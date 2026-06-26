# /pi-run [task-id | "task description"]

Run a task through the Pi/ultimate-pi harness from this Cursor session.
Pi runs in the background via MCP; this session monitors progress and runs
the post-Pi quality gate when done.

## Usage

```text
/pi-run T003
/pi-run "implement payment webhook handler"
/pi-run T003 --risk high
/pi-run T003 --quick
```

## What this command does

1. Read task from `tasks.md` (if task-id) or use description directly
2. Call MCP tool `harness_auto` — Pi starts in background
3. Start a Shell watcher monitoring `.pi/harness/.mcp-state.json` with `notify_on_output`
4. Print a progress line to the user every ~30 s
5. When Pi completes (notified): call `harness_artifacts` to read summary + adversary report
6. Decide next step based on outcome:
   - Review passed → run `/ship T[id]`
   - `block_merge: true` in adversary report → surface findings, ask user
   - Pi failed/aborted → surface last output, suggest `/pi-run` retry

## Prerequisites

- `.cursor/mcp.json` present and `pi-harness` server loaded (Settings → MCP)
- Pi installed, `pi install npm:ultimate-pi`, `/login cursor` done
- `.pi/` harness bootstrapped (`pi → /harness-setup`)
- No other Pi process running (`harness_status` → `process.alive: false`)

## Procedure

### Step 1 — resolve task

If a task-id is given (e.g. `T003`):
- Read `.factory/planning/tasks.md`
- Extract title and objective
- Build task string: `"T003: [title] — [objective]"`

If a free-text description is given, use it directly.

### Step 2 — start Pi

Call MCP tool `harness_auto` with:
- `task`: resolved task string
- `risk`: from flag (default `med`)
- `quick`: from flag (default `false`)

Print to user:

```
Pi harness started — [task]
Monitoring .pi/harness/.mcp-state.json for completion.
```

### Step 3 — watch for completion (same session)

Start a Shell command (background, `block_until_ms: 0`) that polls `.pi/harness/.mcp-state.json`
and prints status lines. Use `notify_on_output` to be notified when done:

```javascript
// node inline script — polls every 30s, prints progress, emits sentinel on done
const fs = require('fs');
let lastLines = 0;
function poll() {
  try {
    const s = JSON.parse(fs.readFileSync('.pi/harness/.mcp-state.json', 'utf8'));
    const lines = s.output_lines || [];
    // Print new output lines
    if (lines.length > lastLines) {
      lines.slice(lastLines).forEach(l => process.stdout.write('[Pi] ' + l + '\n'));
      lastLines = lines.length;
    }
    if (s.completed) {
      process.stdout.write('PI_HARNESS_DONE exit=' + (s.exit_code ?? 0) + '\n');
      process.exit(0);
    }
    // Print phase from active-run if available
    try {
      const run = JSON.parse(fs.readFileSync('.pi/harness/active-run.json', 'utf8'));
      if (run.phase) process.stdout.write('[Pi] phase: ' + run.phase + '\n');
    } catch {}
  } catch {}
  setTimeout(poll, 30000);
}
poll();
```

Shell args:
- `block_until_ms: 0` (immediate background)
- `notify_on_output: { pattern: "PI_HARNESS_DONE", reason: "Pi harness done", debounce_ms: 5000 }`

### Step 4 — on notification: read results

When notified (`PI_HARNESS_DONE`):

Call MCP tools in sequence:
1. `harness_status()` — confirm completed + exit_code
2. `harness_artifacts("executor-summary")` — what Pi implemented
3. `harness_artifacts("adversary-report")` — review findings
4. `harness_artifacts("eval-verdict")` — evaluator verdict

### Step 5 — decide next step

**If `block_merge: true` in adversary-report:**
- Print adversary findings to user
- Ask user: fix findings, replan, or override?
- Do NOT run `/ship` automatically

**If exit_code != 0 (Pi failed/aborted):**
- Print last 20 output lines
- Suggest: `/pi-run T[id]` to retry, or switch to `Engine: cursor` in tasks.md

**If review passed (no block_merge, exit_code 0):**
- Update task status in `tasks.md` → `in-progress` (Pi done, ship pending)
- Run `/ship T[id]` inline to apply Cursor quality gate
- On ship success: update `tasks.md` → `done`, append `diary.md` entry

## Status while running

In a separate Cursor chat, the user can run `/pi-status` to check progress at any time.

## Do not

- Call `harness_auto` if `harness_status` shows `process.alive: true`
- Merge PR without `/ship` gate
- Mark task `done` before `/ship` completes
