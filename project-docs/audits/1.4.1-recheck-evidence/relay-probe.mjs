import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';

mkdirSync('build/audit-recheck', { recursive: true });
const source = readFileSync('supabase/functions/meta-trial-relay/index.ts', 'utf8');
const prefix = `
import assert from 'node:assert/strict';
let calls = 0;
let responseMode = 'network';
const row = {
  id: 'mock-trial', app_user_id: 'mock-customer', status: 'pending',
  original_transaction_id: 'mock-transaction', transaction_id: 'mock-transaction',
  product_id: 'mock-product', store: 'APP_STORE', environment: 'SANDBOX',
  trial_started_at: new Date(Date.now() - 16 * 60000).toISOString(), cancelled_at: null,
};
class Query {
  filters = [];
  updateValue = null;
  select() { return this; }
  eq(key, value) { this.filters.push([key, value]); return this; }
  lte() { return this; }
  order() { return this; }
  limit() { return this; }
  update(value) { this.updateValue = value; return this; }
  then(resolve, reject) {
    const matches = this.filters.every(([key, value]) => row[key] === value);
    if (matches && this.updateValue) Object.assign(row, this.updateValue);
    return Promise.resolve({ data: matches ? [{ ...row }] : [], error: null }).then(resolve, reject);
  }
}
const createClient = () => ({ from: () => new Query() });
globalThis.Deno = {
  env: { get: (key) => key === 'META_RELAY_RC_SECRET_KEY' ? 'mock-only-token' : '' },
  serve: () => {},
};
globalThis.fetch = async () => {
  calls += 1;
  if (responseMode === 'network') throw new Error('Mock temporary network outage');
  return new Response('{}', { status: 429 });
};
`;
const suffix = `
const results = [];
for (const mode of ['network', '429']) {
  responseMode = mode;
  row.status = 'pending';
  calls = 0;
  await sweep();
  const firstStatus = row.status;
  await sweep();
  assert.equal(firstStatus, 'error');
  assert.equal(calls, 1);
  results.push({ failure: mode, statusAfterFirstSweep: firstStatus, revenueCatCallsAfterTwoSweeps: calls });
}
console.log(JSON.stringify(results, null, 2));
`;
const program = prefix + source.replace(/^import \{ createClient \} from .*;$/m, '') + suffix;
const path = 'build/audit-recheck/relay-probe-generated.ts';
writeFileSync(path, program);
console.log('Relay source SHA-256:', createHash('sha256').update(source).digest('hex'));
const result = spawnSync(process.execPath, [path], { encoding: 'utf8' });
process.stdout.write(result.stdout);
process.stderr.write(result.stderr);
assert.equal(result.status, 0);
