import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const source = await readFile(new URL('./worker.js', import.meta.url), 'utf8');
const { default: worker } = await import(`data:text/javascript;base64,${Buffer.from(source).toString('base64')}`);
const payload = { appid: 'com.retrace.lorettapp', pushToken: '', userAgent: 'ReTrace test', appsAttr: '{}', adjustAdid: 'test-adjust-id', oneLink: '' };
const launch = (body = payload, env = {}) => worker.fetch(new Request('https://rtrace.xyz/retraceuser', {
  method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
}), env);
const native = await launch();
assert.equal(native.status, 200);
assert.equal(native.headers.get('cache-control'), 'no-store');
const decision = await native.json();
assert.equal(decision.retraceFlow, 'questLog');
assert.ok(decision.projectTemplates.length > 0);
assert.ok(decision.projectTemplates.every(t => t.title && t.category));
assert.ok(!('url' in decision));
const web = await launch(payload, { RETRACE_WEB_URL: 'https://example.com/start' });
assert.deepEqual(await web.json(), { retraceFlow: 'retraceHub', url: 'https://example.com/start' });
assert.equal((await launch(payload, { RETRACE_WEB_URL: 'javascript:alert(1)' })).status, 503);
assert.equal((await launch({ ...payload, idfa: 'forbidden' })).status, 400);
assert.equal((await launch({ appid: 'other.app' })).status, 400);
assert.equal((await launch({ ...payload, appsAttr: 42 })).status, 400);
assert.equal((await launch(null)).status, 400);
assert.equal((await launch({ ...payload, oneLink: 'x'.repeat(33000) })).status, 413);
assert.equal((await worker.fetch(new Request('https://rtrace.xyz/retraceuser', { method: 'POST', headers: { 'content-type': 'application/json' }, body: '{' }), {})).status, 400);
const method = await worker.fetch(new Request('https://rtrace.xyz/retraceuser'), {});
assert.equal(method.status, 405);
assert.equal(method.headers.get('allow'), 'POST');
assert.equal((await worker.fetch(new Request('https://rtrace.xyz/'), {})).status, 200);
assert.equal((await worker.fetch(new Request('https://rtrace.xyz/privacy'), {})).status, 200);
assert.equal((await worker.fetch(new Request('https://rtrace.xyz/api/contact', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ website: 'bot' }) }), {})).status, 200);
console.log('Worker checks passed: native/web contract, validation, IDFA rejection, size limits, marketing and support routes.');

const stored = [];
const logEnv = { RETRACE_LAUNCH_LOGS: { put: async (...args) => stored.push(args) } };
assert.equal((await launch({ ...payload, unknown: "do not store" }, logEnv)).status, 200);
assert.equal(stored.length, 1);
const entry = JSON.parse(stored[0][1]);
assert.equal(entry.received.appid, payload.appid);
assert.equal(entry.received.appsAttr, "{}");
assert.equal(entry.received.pushToken, "");
assert.ok(!("deviceName" in entry.received));
assert.ok(!("unknown" in entry.received));
assert.ok(!("idfa" in entry.received));
assert.equal(stored[0][2].expirationTtl, 86400);
assert.equal((await launch({ ...payload, idfa: "forbidden" }, logEnv)).status, 400);
assert.equal(stored.length, 1);
const previousError = console.error;
const errors = [];
console.error = message => errors.push(message);
try {
  assert.equal((await launch(payload, { RETRACE_LAUNCH_LOGS: { put: async () => { throw new Error("test failure"); } } })).status, 200);
} finally {
  console.error = previousError;
}
assert.deepEqual(errors, ["ReTrace launch log write failed."]);
console.log("Cloudflare log checks passed: allowlisted metadata, 24h TTL, IDFA rejection, failure isolation.");
