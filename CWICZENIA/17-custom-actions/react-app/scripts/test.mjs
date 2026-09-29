import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

// Keep the Jest flags used by the existing GitHub Actions exercises working.
const aliases = new Map([
  ['--ci', '--run'],
  ['--watchAll=false', '--watch=false'],
  ['--watchAll', '--watch'],
  ['--watchAll=true', '--watch'],
  ['--runInBand', '--no-file-parallelism'],
]);
const args = process.argv.slice(2).map((arg) => aliases.get(arg) ?? arg);
const cli = fileURLToPath(new URL('../node_modules/vitest/vitest.mjs', import.meta.url));
const result = spawnSync(process.execPath, [cli, 'run', ...args], { stdio: 'inherit' });
if (result.error) console.error(result.error.message);
process.exit(result.status ?? 1);
