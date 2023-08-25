create table if not exists todos (
  id uuid primary key default uuid_generate_v4(),
  description text not null,
  complete boolean not null default false,
  created_at timestamptz default (now() at time zone 'utc'::text) not null
);

