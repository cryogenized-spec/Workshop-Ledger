create extension if not exists pgcrypto;

create table custodians (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  org text not null,
  phone text,
  email text,
  created_at timestamptz default now()
);

create table items (
  id uuid primary key default gen_random_uuid(),
  sku text,
  name text not null,
  type text not null,
  serial text,
  model_number text,
  current_custodian uuid references custodians(id),
  status text default 'active',
  notes text,
  photo_url text,
  created_at timestamptz default now()
);

create table job_cards (
  id uuid primary key default gen_random_uuid(),
  ref text unique not null,
  client_name text,
  description text,
  status text default 'open',
  opened_at timestamptz default now(),
  closed_at timestamptz
);

create table transfers (
  id uuid primary key default gen_random_uuid(),
  item_id uuid references items(id),
  from_custodian_id uuid references custodians(id),
  to_custodian_id uuid references custodians(id),
  job_card_ref text,
  qty_moved int default 1,
  qty_remaining int default 0,
  reason text,
  transferred_by uuid,
  transferred_at timestamptz default now(),
  signature_png text,
  photos text[] default '{}'
);

create table consumables_log (
  id uuid primary key default gen_random_uuid(),
  item_id uuid references items(id),
  type text default 'CO2',
  qty_in int default 0,
  qty_out int default 0,
  balance int default 0,
  related_transfer_id uuid references transfers(id),
  notes text,
  created_at timestamptz default now()
);

create or replace function update_item_custodian()
returns trigger as $$
begin
  update items set current_custodian = new.to_custodian_id where id = new.item_id;
  return new;
end;
$$ language plpgsql;

create trigger trg_update_item_custodian
after insert on transfers
for each row execute procedure update_item_custodian();

alter table custodians enable row level security;
alter table items enable row level security;
alter table job_cards enable row level security;
alter table transfers enable row level security;
alter table consumables_log enable row level security;

create policy "auth read" on custodians for select to authenticated using (true);
create policy "auth insert" on custodians for insert to authenticated with check (true);
create policy "auth read items" on items for select to authenticated using (true);
create policy "auth insert items" on items for insert to authenticated with check (true);
create policy "auth update items" on items for update to authenticated using (true);
create policy "auth read jobs" on job_cards for select to authenticated using (true);
create policy "auth insert jobs" on job_cards for insert to authenticated with check (true);
create policy "auth update jobs" on job_cards for update to authenticated using (true);
create policy "auth read transfers" on transfers for select to authenticated using (true);
create policy "auth insert transfers" on transfers for insert to authenticated with check (true);
create policy "no delete transfers" on transfers for delete to authenticated using (false);

insert into custodians(name,org) values
('Gareth','Vanguard'),
('Neon Sales Counter','Neon Sales');
