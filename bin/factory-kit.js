#!/usr/bin/env node
'use strict';

const { execFileSync, spawnSync } = require('node:child_process');
const { existsSync, readFileSync } = require('node:fs');
const { join, resolve } = require('node:path');

const PKG_DIR = join(__dirname, '..');
const VERSION = readFileSync(join(PKG_DIR, 'VERSION'), 'utf8').trim();

const REPO_URL = 'https://github.com/eskobar95/factory.git';
const KIT_PATH = '.factory/kit';

// ── helpers ───────────────────────────────────────────────────────────────────

function run(cmd, args, opts = {}) {
  const result = spawnSync(cmd, args, {
    stdio: 'inherit',
    cwd: opts.cwd ?? process.cwd(),
    ...opts,
  });
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

function isGitRepo(dir) {
  const result = spawnSync('git', ['rev-parse', '--git-dir'], {
    cwd: dir,
    stdio: 'pipe',
  });
  return result.status === 0;
}

function die(msg) {
  console.error(`\nError: ${msg}\n`);
  process.exit(1);
}

function header(msg) {
  console.log(`\n==> ${msg}`);
}

// ── commands ──────────────────────────────────────────────────────────────────

function cmdInstall() {
  const projectRoot = process.cwd();

  if (!isGitRepo(projectRoot)) {
    die('Not a git repository. Run "git init" first.');
  }

  // If installed via npx, we copy files from the npm package directly.
  // If run from a local clone, we still add the submodule.
  const useSubmodule = !existsSync(join(PKG_DIR, 'node_modules'));

  if (useSubmodule) {
    header(`Adding factory-kit submodule → ${KIT_PATH}`);
    if (!existsSync(join(projectRoot, KIT_PATH, 'install.sh'))) {
      run('git', ['submodule', 'add', REPO_URL, KIT_PATH]);
      run('git', ['submodule', 'update', '--init', '--recursive']);
    } else {
      console.log(`    ${KIT_PATH} already exists — skipping submodule add`);
    }
    run('bash', [join(projectRoot, KIT_PATH, 'install.sh')]);
  } else {
    // Installed via npx — use files from npm package
    header('Installing factory-kit from npm package');
    if (!existsSync(join(projectRoot, KIT_PATH))) {
      run('mkdir', ['-p', KIT_PATH]);
      // Copy kit files into .factory/kit/
      run('cp', ['-r', `${PKG_DIR}/.`, KIT_PATH]);
      console.log(`    Copied kit → ${KIT_PATH}`);
    } else {
      console.log(`    ${KIT_PATH} already exists`);
    }
    run('bash', [join(projectRoot, KIT_PATH, 'install.sh')]);
  }
}

function cmdUpdate() {
  const projectRoot = process.cwd();
  const updateScript = join(projectRoot, KIT_PATH, 'update.sh');

  if (!existsSync(updateScript)) {
    die(`Factory kit not found at ${KIT_PATH}. Run "factory-kit install" first.`);
  }

  header('Updating factory-kit');
  run('bash', [updateScript]);
}

function cmdBootstrapPi() {
  const projectRoot = process.cwd();
  const script = join(projectRoot, KIT_PATH, 'scripts', 'bootstrap-pi.sh');

  if (!existsSync(script)) {
    die(`Factory kit not found at ${KIT_PATH}. Run "factory-kit install" first.`);
  }

  header('Bootstrapping Pi harness');
  run('bash', [script]);
}

function cmdVersion() {
  console.log(`factory-kit v${VERSION}`);
}

function cmdHelp() {
  console.log(`
factory-kit v${VERSION} — Factory 2.0 CLI

Usage:
  factory-kit <command>

Commands:
  install        Install factory-kit into the current project (git submodule + scaffold)
  update         Pull latest kit and re-copy .cursor/ files
  bootstrap-pi   Set up Pi harness, install pi-cursor-provider, sync model routing
  version        Print version
  help           Show this help

Examples:
  # New project
  cd my-project
  npx @eskoubar95/factory-kit install

  # Update existing project
  npx @eskoubar95/factory-kit update

  # Enable Pi after install
  npx @eskoubar95/factory-kit bootstrap-pi

Docs: https://github.com/eskobar95/factory
`);
}

// ── main ──────────────────────────────────────────────────────────────────────

const [,, subcmd, ...args] = process.argv;

switch (subcmd) {
  case 'install':      cmdInstall(); break;
  case 'update':       cmdUpdate(); break;
  case 'bootstrap-pi': cmdBootstrapPi(); break;
  case 'version':
  case '--version':
  case '-v':           cmdVersion(); break;
  case 'help':
  case '--help':
  case '-h':
  case undefined:      cmdHelp(); break;
  default:
    console.error(`Unknown command: ${subcmd}`);
    cmdHelp();
    process.exit(1);
}
