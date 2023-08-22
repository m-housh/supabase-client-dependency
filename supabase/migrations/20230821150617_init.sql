create table if not exists todos (
  id uuid primary key default uuid_generate_v4(),
  description text not null,
  complete boolean not null default false,
  owner_id uuid references auth.users (id) not null,
  created_at timestamptz default (now() at time zone 'utc'::text) not null
);

alter table todos enable row level security;

create policy "Allow access to owner only" on todos as permissive
    for all to authenticated
        using (auth.uid () = owner_id)
        with check (auth.uid () = owner_id);
