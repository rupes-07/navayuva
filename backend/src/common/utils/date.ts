export function toIsoDate(value: Date): string {
  return value.toISOString();
}

export function normalizeDateRange(start?: string, end?: string): { start?: Date; end?: Date } {
  const startDate = start ? new Date(start) : undefined;
  const endDate = end ? new Date(end) : undefined;
  if (startDate && Number.isNaN(startDate.getTime())) {
    throw new Error('Invalid start date');
  }
  if (endDate && Number.isNaN(endDate.getTime())) {
    throw new Error('Invalid end date');
  }
  if (startDate && endDate && startDate > endDate) {
    throw new Error('Start date must not be after end date');
  }
  return { start: startDate, end: endDate };
}
