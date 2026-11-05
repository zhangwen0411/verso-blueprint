import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';
import vm from 'node:vm';

const script = await readFile(new URL(
  '../src/VersoBlueprint/Informal/Block/declaration-source.js', import.meta.url), 'utf8');

test('registered declaration previews delegate with the existing hover table', async () => {
  let load, options;
  const body = {};
  const context = {
    window: { addEventListener(event, callback) { assert.equal(event, 'load'); load = callback; } },
    fetch: async path => {
      assert.equal(path, '-verso-docs.json');
      return { ok: true, json: async () => ({ 1000001: '<code>Nat</code>' }) };
    },
    MutationObserver: class { observe() {} },
    document: { body, querySelectorAll: () => [],
      createElement: () => ({ style: {}, querySelectorAll: () => [] }) },
    tippy: { delegate(root, config) { assert.equal(root, body); options = config; } }
  };
  vm.runInNewContext(script, context);
  await load();
  assert.equal(options.target,
    '.declaration:has(.bp_external_decl_source_code) [data-verso-hover]');
  assert.equal(options.theme, 'lean');
  assert.equal(options.appendTo(), body);
  const content = options.content({ dataset: { versoHover: '1000001' } });
  assert.equal(content.innerHTML, '<code>Nat</code>');
  assert.equal(content.className, 'hl lean');
});

test('inserted registered documentation becomes prose without hidden metadata', async () => {
  let load, hydrate, replacement, removed = false;
  const clone = {
    querySelectorAll: () => [{ remove() { removed = true; } }],
    get textContent() { return removed ? 'Visible documentation' : 'Hidden metadata'; }
  };
  const doc = { cloneNode: () => clone, replaceWith(node) { replacement = node; } };
  vm.runInNewContext(script, {
    window: { addEventListener(_event, callback) { load = callback; } },
    fetch: async () => ({ ok: true, json: async () => ({}) }),
    tippy: { delegate() {} },
    marked: { parse: text => '<p>' + text + '</p>' },
    MutationObserver: class { constructor(callback) { hydrate = callback; } observe() {} },
    document: { body: {}, querySelectorAll: () => [], createElement: tag => ({ tag }) }
  });
  await load();
  hydrate([{ addedNodes: [{ nodeType: 1, querySelectorAll(selector) {
    assert.match(selector, /declaration:has\(\.bp_external_decl_source_code\)/);
    return [doc];
  } }] }]);
  assert.equal(replacement.tag, 'div');
  assert.equal(replacement.className, 'docstring');
  assert.equal(replacement.innerHTML, '<p>Visible documentation</p>');
});
