export type PaginationInput = {
  page: number;
  limit: number;
  sort: string;
  order: 'asc' | 'desc';
};

export type PaginationMeta = {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
};
