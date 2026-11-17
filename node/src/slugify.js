export function slugify(value) {
  if (typeof value !== 'string' || value.trim() === '') {
    throw new TypeError('Value must be a non-empty string');
  }

  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
}
