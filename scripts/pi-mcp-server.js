#!/usr/bin/env node
/**
 * pi-mcp-server.js — MCP bridge: Cursor ↔ Pi/ultimate-pi harness
 *
 * Exposes Pi harness commands as Cursor MCP tools.
 * Pi processes run in the background; use harness_status to poll progress.
 *
 * Install: copy templates/mcp.json → .cursor/mcp.json (done by install.sh)
 * Requires: Pi installed (https://pi.dev) + pi install npm:ultimate-pi
 */

'use strict';

const { spawn, execFileSync } = require('node:child_process');
const { existsSync, readFileSync, readdirSync, mkdirSync, writeFileSync } = require('node:fs');
const { join } = require('node:path');
const { homedir } = require('node:os');
const readline = require('node:readline');

// ── Pi binary discovery ───────────────────────────────────────────────────────

function findPiBin() {
  const candidates = [
    process.env.PI_BIN,
    join(homedir(), '.hermes', 'node', 'bin', 'pi'),
    '/usr/local/bin/pi',
    '/opt/homebrew/bin/pi',
  ].filter(Boolean);

  for (const c of candidates) {
    if (existsSync(c)) return c;
  }
  try {
    return execFileSync('which', ['pi'], { encoding: 'utf8' }).trim();
  } catch {}
  return null;
}

// ── Paths ─────────────────────────────────────────────────────────────────────

const PROJECT_ROOT = process.cwd();
const HARNESS_DIR = join(PROJECT_ROOT, '.pi', 'harness');
const ACTIVE_RUN_FILE = join(HARNESS_DIR, 'active-run.json');
const MCP_STATE_FILE = join(HARNESS_DIR, '.mcp-state.json');

// ── State helpers ─────────────────────────────────────────────────────────────

function readJson(path) {
  try { return JSON.parse(readFileSync(path, 'utf8')); } catch { return null; }
}

function readMcpState() {
  return readJson(MCP_STATE_FILE) ?? { completed: true, pid: null, command: null };
}

function writeMcpState(patch) {
  try {
    mkdirSync(HARNESS_DIR, { recursive: true });
    writeFileSync(MCP_STATE_FILE, JSON.stringify({ ...readMcpState(), ...patch }, null, 2));
  } catch {}
}

function isProcessAlive(pid) {
  if (!pid) return false;
  try { process.kill(pid, 0); return true; } catch { return false; }
}

// ── Harness file readers ──────────────────────────────────────────────────────

function readRunContext(runId) {
  const path = join(HARNESS_DIR, 'runs', runId, 'run-context.yaml');
  try {
    const result = {};
    for (const line of readFileSync(path, 'utf8').split('\n')) {
      const m = line.match(/^([\w_-]+):\s*(.+)/);
      if (m) result[m[1]] = m[2].replace(/^['"]|['"]$/g, '');
    }
    return result;
  } catch { return null; }
}

function listArtifacts(runId) {
  try {
    return readdirSync(join(HARNESS_DIR, 'runs', runId, 'artifacts'));
  } catch { return []; }
}

function readArtifact(runId, name) {
  const base = join(HARNESS_DIR, 'runs', runId, 'artifacts');
  for (const p of [join(base, name), join(base, `${name}.yaml`), join(base, `${name}.json`)]) {
    if (existsSync(p)) return readFileSync(p, 'utf8');
  }
  // executor-summary lives in handoff/
  if (name === 'executor-summary') {
    const p = join(HARNESS_DIR, 'runs', runId, 'handoff', 'executor-summary.yaml');
    if (existsSync(p)) return readFileSync(p, 'utf8');
  }
  return null;
}

// ── Pi spawner ────────────────────────────────────────────────────────────────

function spawnPi(piBin, command) {
  const env = {
    ...process.env,
    PATH: `${join(homedir(), '.hermes', 'node', 'bin')}:${process.env.PATH ?? ''}`,
  };

  const child = spawn(piBin, ['--print', command], {
    cwd: PROJECT_ROOT,
    env,
    stdio: ['ignore', 'pipe', 'pipe'],
  });

  const lines = [];

  const onData = (prefix) => (chunk) => {
    const newLines = chunk.toString().split('\n')
      .map(l => l.trim()).filter(Boolean)
      .map(l => prefix ? `[${prefix}] ${l}` : l);
    lines.push(...newLines);
    writeMcpState({ output_lines: lines.slice(-80) });
  };

  child.stdout.on('data', onData(null));
  child.stderr.on('data', onData('err'));
  child.on('exit', (code) => {
    writeMcpState({ completed: true, exit_code: code, finished_at: new Date().toISOString() });
  });

  return child;
}

function guardPiAvailable() {
  const piBin = findPiBin();
  if (!piBin) return { error: 'Pi not found. Install from https://pi.dev and ensure ~/.hermes/node/bin is in PATH. Or set PI_BIN env var.' };
  return { ok: true, piBin };
}

function guardNoActiveRun() {
  const state = readMcpState();
  if (state.pid && !state.completed && isProcessAlive(state.pid)) {
    return { error: `Pi is already running (pid ${state.pid}, command: ${state.command}). Use harness_status to check progress or harness_abort to stop.` };
  }
  return { ok: true };
}

// ── Tool definitions ──────────────────────────────────────────────────────────

const TOOLS = {

  harness_auto: {
    description: 'Run the full Pi harness pipeline (plan → execute → review) for a task. Starts Pi in the background and returns immediately. Call harness_status to poll progress.',
    inputSchema: {
      type: 'object',
      required: ['task'],
      properties: {
        task:  { type: 'string', description: 'Task description' },
        risk:  { type: 'string', enum: ['low', 'med', 'high'], description: 'Risk level (default: med)' },
        quick: { type: 'boolean', description: 'Skip heavy planning debate (faster, less thorough)' },
      },
    },
    async run({ task, risk = 'med', quick = false }) {
      const piCheck = guardPiAvailable();
      if (piCheck.error) return piCheck;
      const runCheck = guardNoActiveRun();
      if (runCheck.error) return runCheck;

      const flags = [quick && '--quick', `--risk ${risk}`].filter(Boolean).join(' ');
      const cmd = `/harness-auto "${task.replace(/"/g, '\\"')}" ${flags}`.trim();
      const child = spawnPi(piCheck.piBin, cmd);

      writeMcpState({ pid: child.pid, command: 'harness_auto', task, started_at: new Date().toISOString(), completed: false, output_lines: [] });

      return {
        started: true,
        pid: child.pid,
        message: 'Pi harness started. Call harness_status to poll phase and output. Call harness_artifacts when complete.',
      };
    },
  },

  harness_plan: {
    description: 'Run Pi harness planning phase only. Starts Pi in the background. Call harness_status to poll.',
    inputSchema: {
      type: 'object',
      required: ['task'],
      properties: {
        task:  { type: 'string' },
        risk:  { type: 'string', enum: ['low', 'med', 'high'] },
        quick: { type: 'boolean' },
      },
    },
    async run({ task, risk = 'med', quick = false }) {
      const piCheck = guardPiAvailable();
      if (piCheck.error) return piCheck;
      const runCheck = guardNoActiveRun();
      if (runCheck.error) return runCheck;

      const flags = [quick && '--quick', `--risk ${risk}`].filter(Boolean).join(' ');
      const cmd = `/harness-plan "${task.replace(/"/g, '\\"')}" ${flags}`.trim();
      const child = spawnPi(piCheck.piBin, cmd);

      writeMcpState({ pid: child.pid, command: 'harness_plan', task, started_at: new Date().toISOString(), completed: false, output_lines: [] });

      return { started: true, pid: child.pid, message: 'Planning started. Poll harness_status.' };
    },
  },

  harness_run: {
    description: 'Run Pi harness execution phase. Requires an approved plan from harness_plan. Starts Pi in the background.',
    inputSchema: { type: 'object', properties: {} },
    async run() {
      const piCheck = guardPiAvailable();
      if (piCheck.error) return piCheck;
      const runCheck = guardNoActiveRun();
      if (runCheck.error) return runCheck;

      const active = readJson(ACTIVE_RUN_FILE);
      if (!active?.run_id) return { error: 'No active harness run found. Run harness_plan first.' };

      const child = spawnPi(piCheck.piBin, '/harness-run');
      writeMcpState({ pid: child.pid, command: 'harness_run', started_at: new Date().toISOString(), completed: false, output_lines: [] });

      return { started: true, pid: child.pid, run_id: active.run_id, message: 'Execution started. Poll harness_status.' };
    },
  },

  harness_review: {
    description: 'Run Pi harness review phase (evaluator + adversary + tie-breaker). Starts Pi in the background.',
    inputSchema: {
      type: 'object',
      properties: {
        quick: { type: 'boolean', description: 'Skip heavy adversary pass' },
      },
    },
    async run({ quick = false } = {}) {
      const piCheck = guardPiAvailable();
      if (piCheck.error) return piCheck;
      const runCheck = guardNoActiveRun();
      if (runCheck.error) return runCheck;

      const cmd = quick ? '/harness-review --quick' : '/harness-review';
      const child = spawnPi(piCheck.piBin, cmd);
      writeMcpState({ pid: child.pid, command: 'harness_review', started_at: new Date().toISOString(), completed: false, output_lines: [] });

      return { started: true, pid: child.pid, message: 'Review started. Poll harness_status.' };
    },
  },

  harness_status: {
    description: 'Poll Pi harness status: current phase, process liveness, recent output lines, and run context. Call this repeatedly to monitor progress.',
    inputSchema: { type: 'object', properties: {} },
    async run() {
      const state = readMcpState();
      const active = readJson(ACTIVE_RUN_FILE);
      const runCtx = active?.run_id ? readRunContext(active.run_id) : null;

      const alive = isProcessAlive(state.pid);
      if (!alive && !state.completed) writeMcpState({ completed: true });

      const artifacts = active?.run_id ? listArtifacts(active.run_id) : [];

      return {
        process: {
          alive,
          pid: state.pid,
          command: state.command,
          started_at: state.started_at,
          completed: state.completed || !alive,
          exit_code: state.exit_code ?? null,
          finished_at: state.finished_at ?? null,
        },
        harness: {
          run_id: active?.run_id ?? null,
          phase: runCtx?.phase ?? active?.phase ?? null,
          status: runCtx?.status ?? null,
          plan_status: runCtx?.plan_status ?? null,
        },
        available_artifacts: artifacts,
        recent_output: (state.output_lines ?? []).slice(-30),
      };
    },
  },

  harness_artifacts: {
    description: 'Read a harness artifact from the active run. Omit name to list available artifacts.',
    inputSchema: {
      type: 'object',
      properties: {
        name: {
          type: 'string',
          description: 'Artifact name without extension (e.g. "executor-summary", "adversary-report", "eval-verdict", "plan-packet"). Omit to list.',
        },
      },
    },
    async run({ name } = {}) {
      const active = readJson(ACTIVE_RUN_FILE);
      if (!active?.run_id) return { error: 'No active harness run.' };

      if (!name) {
        return {
          run_id: active.run_id,
          available: [
            'executor-summary',
            ...listArtifacts(active.run_id),
          ],
        };
      }

      const content = readArtifact(active.run_id, name);
      if (!content) return { error: `Artifact "${name}" not found in run ${active.run_id}.`, available: listArtifacts(active.run_id) };

      return { run_id: active.run_id, artifact: name, content };
    },
  },

  harness_abort: {
    description: 'Abort the currently running Pi harness process.',
    inputSchema: {
      type: 'object',
      properties: {
        reason: { type: 'string', description: 'Abort reason' },
      },
    },
    async run({ reason = 'aborted via MCP' } = {}) {
      const state = readMcpState();

      if (state.pid && !state.completed && isProcessAlive(state.pid)) {
        process.kill(state.pid, 'SIGTERM');
        writeMcpState({ completed: true, aborted: true, abort_reason: reason, finished_at: new Date().toISOString() });

        // Also send harness-abort for clean Pi state
        const piBin = findPiBin();
        if (piBin) {
          try {
            spawnPi(piBin, `/harness-abort "${reason.replace(/"/g, '\\"')}"`);
          } catch {}
        }

        return { aborted: true, pid: state.pid, reason };
      }

      return { aborted: false, message: 'No active Pi process running.' };
    },
  },
};

// ── MCP JSON-RPC 2.0 stdio server ─────────────────────────────────────────────

async function handleRequest(req) {
  const { id, method, params = {} } = req;

  const ok  = (result) => ({ jsonrpc: '2.0', id, result });
  const err = (code, message) => ({ jsonrpc: '2.0', id, error: { code, message } });

  switch (method) {
    case 'initialize':
      return ok({
        protocolVersion: '2024-11-05',
        serverInfo: { name: 'pi-harness', version: '1.0.0' },
        capabilities: { tools: {} },
      });

    case 'tools/list':
      return ok({
        tools: Object.entries(TOOLS).map(([name, def]) => ({
          name,
          description: def.description,
          inputSchema: def.inputSchema,
        })),
      });

    case 'tools/call': {
      const { name, arguments: args = {} } = params;
      const tool = TOOLS[name];
      if (!tool) return err(-32601, `Unknown tool: ${name}`);
      try {
        const result = await tool.run(args);
        return ok({ content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] });
      } catch (e) {
        return err(-32000, `Tool error: ${e.message}`);
      }
    }

    default:
      return err(-32601, `Method not found: ${method}`);
  }
}

const rl = readline.createInterface({ input: process.stdin, crlfDelay: Infinity });

rl.on('line', async (line) => {
  const trimmed = line.trim();
  if (!trimmed) return;

  let req;
  try {
    req = JSON.parse(trimmed);
  } catch {
    process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id: null, error: { code: -32700, message: 'Parse error' } }) + '\n');
    return;
  }

  // Notifications have no id — no response needed
  if (req.method?.startsWith('notifications/')) return;

  const response = await handleRequest(req);
  process.stdout.write(JSON.stringify(response) + '\n');
});

rl.on('close', () => process.exit(0));

process.stderr.write(`[pi-harness MCP] started — project: ${PROJECT_ROOT}\n`);
