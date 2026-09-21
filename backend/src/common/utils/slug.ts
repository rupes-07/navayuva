export function slugify(value: string): string {
  return value
    .trim()
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

export function createUniqueSlug(value: string, suffix: string): string {
  const base = slugify(value) || 'item';
  return `${base}-${suffix.slice(0, 12)}`;
}
