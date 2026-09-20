export const ISSUE_CATEGORIES = [
  'Education',
  'Roads',
  'Water',
  'Waste',
  'Health',
  'Environment',
  'Employment',
  'Tourism',
  'Infrastructure',
  'Public Safety',
  'Culture',
  'Youth',
  'Other',
] as const;

export type IssueCategoryName = (typeof ISSUE_CATEGORIES)[number];
