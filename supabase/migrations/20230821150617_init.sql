create table if not exists todos (
  id uuid primary key default uuid_generate_v4(),
  description text not null,
  complete boolean not null default false,
  created_at timestamptz default (now() at time zone 'utc'::text) not null,
  owner_id uuid references auth.users (id) not null
);


alter table todos enable row level security;

create policy "Allow access to owner only" on todos as permissive
    for all to authenticated
        using (auth.uid () = owner_id)
        with check (auth.uid () = owner_id);
