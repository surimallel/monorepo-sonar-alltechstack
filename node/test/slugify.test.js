import assert from 'node:assert/strict';
import test from 'node:test';
import { slugify } from '../src/slugify.js';

test('turns words and punctuation into a lowercase URL slug', () => {
  assert.equal(slugify('  Hello, Node.js!  '), 'hello-node-js');
});

test('rejects empty and non-string values', () => {
  assert.throws(() => slugify('  '), TypeError);
  assert.throws(() => slugify(null), TypeError);
});
