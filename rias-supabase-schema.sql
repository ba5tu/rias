-- RIAS – Supabase-skeema
-- Aja tämä kokonaisuudessaan Supabasen SQL Editorissa (Supabase-projektin sivu -> SQL Editor -> New query)

create table if not exists world_state (
  id int primary key default 1,
  role text not null default 'atc',
  constraint world_state_single_row check (id = 1)
);

create table if not exists vehicles (
  id text primary key,
  label text not null,
  tracking text not null default 'app',        -- 'app' | 'tag'
  route_mode text not null default 'taxiway',   -- 'taxiway' | 'gate'
  lane_x int not null,
  start_x int not null,
  start_y int not null,
  phase text not null default 'apron',          -- 'apron' | 'hold' | 'strip'
  announced boolean not null default false,
  visual text not null default 'normal',        -- 'normal' | 'pending' | 'working' | 'alert'
  roll_call_pending boolean not null default false,
  updated_at timestamptz not null default now()
);

create table if not exists log (
  id bigserial primary key,
  ts timestamptz not null default now(),
  text text not null,
  kind text not null default 'info'             -- 'info' | 'working' | 'authorized' | 'alert'
);

-- Row Level Security: pidetään auki (anon-avaimella luku+kirjoitus) koska tämä on
-- sisäinen pilotti-/demokäyttö ilman kirjautumista. HUOM: anon-avain on julkinen
-- selaimen koodissa, joten kuka tahansa linkin saanut voi kirjoittaa dataa tähän
-- vaiheessa. Ennen laajempaa/tuotantokäyttöä: lisää Supabase Auth ja tiukempi RLS.

alter table world_state enable row level security;
alter table vehicles enable row level security;
alter table log enable row level security;

create policy "anon select world_state" on world_state for select using (true);
create policy "anon update world_state" on world_state for update using (true) with check (true);

create policy "anon select vehicles" on vehicles for select using (true);
create policy "anon insert vehicles" on vehicles for insert with check (true);
create policy "anon update vehicles" on vehicles for update using (true) with check (true);

create policy "anon select log" on log for select using (true);
create policy "anon insert log" on log for insert with check (true);

-- Alkutila
insert into world_state (id, role) values (1, 'atc')
  on conflict (id) do nothing;

insert into vehicles (id, label, tracking, route_mode, lane_x, start_x, start_y, phase)
values
  ('v1', 'Ajoneuvo 1 (kunnossapito)', 'app', 'taxiway', 812, 845, 72, 'apron'),
  ('v2', 'Ajoneuvo 2 (maahuolinta)', 'app', 'taxiway', 828, 796, 77, 'apron')
on conflict (id) do nothing;

-- Realtime: ilman tätä muutokset eivät välity live-tilassa muille selaimille
alter publication supabase_realtime add table vehicles;
alter publication supabase_realtime add table world_state;
alter publication supabase_realtime add table log;
