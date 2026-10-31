-- RIAS – EFET-demon (efet.html) taulut samaan demoprojektiin kuin EFLP-demo
-- Aja tämä kokonaisuudessaan Supabasen SQL Editorissa (demon Supabase-projekti -> SQL Editor -> New query).
-- Omat taulut (efet_*), jotta EFET- ja EFLP-demon ajoneuvot ja lokit eivät sekoitu.
-- Ei uutta projektia, joten Supabasen kustannus ei muutu. Turvallista ajaa uudelleen.

create table if not exists efet_world_state (
  id int primary key default 1,
  role text not null default 'afis',            -- 'afis' (AFIS palvelussa) | 'pelastus' (AFIS ei palvelussa)
  constraint efet_world_state_single_row check (id = 1)
);

create table if not exists efet_vehicles (
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

create table if not exists efet_log (
  id bigserial primary key,
  ts timestamptz not null default now(),
  text text not null,
  kind text not null default 'info'             -- 'info' | 'working' | 'authorized' | 'alert'
);

-- Row Level Security: auki anon-avaimella samalla tavalla kuin EFLP-demossa (julkinen demo ilman kirjautumista).
-- HUOM: anon-avain on julkinen selaimen koodissa, joten kuka tahansa linkin saanut voi kirjoittaa dataa.
alter table efet_world_state enable row level security;
alter table efet_vehicles enable row level security;
alter table efet_log enable row level security;

drop policy if exists "anon select efet_world_state" on efet_world_state;
drop policy if exists "anon update efet_world_state" on efet_world_state;
drop policy if exists "anon select efet_vehicles" on efet_vehicles;
drop policy if exists "anon insert efet_vehicles" on efet_vehicles;
drop policy if exists "anon update efet_vehicles" on efet_vehicles;
drop policy if exists "anon delete efet_vehicles" on efet_vehicles;
drop policy if exists "anon select efet_log" on efet_log;
drop policy if exists "anon insert efet_log" on efet_log;

create policy "anon select efet_world_state" on efet_world_state for select using (true);
create policy "anon update efet_world_state" on efet_world_state for update using (true) with check (true);
create policy "anon select efet_vehicles" on efet_vehicles for select using (true);
create policy "anon insert efet_vehicles" on efet_vehicles for insert with check (true);
create policy "anon update efet_vehicles" on efet_vehicles for update using (true) with check (true);
create policy "anon delete efet_vehicles" on efet_vehicles for delete using (true);
create policy "anon select efet_log" on efet_log for select using (true);
create policy "anon insert efet_log" on efet_log for insert with check (true);

-- Taulutason oikeudet (ilman näitä selain saa virheen "permission denied for table ...")
grant usage on schema public to anon;
grant select, update on efet_world_state to anon;
grant select, insert, update, delete on efet_vehicles to anon;
grant select, insert on efet_log to anon;
grant usage, select on sequence efet_log_id_seq to anon;

-- Alkutila. Paikat ovat efet.html:n kaavion koordinaatteja (asemataso kiitotien alapuolella).
insert into efet_world_state (id, role) values (1, 'afis')
  on conflict (id) do nothing;

insert into efet_vehicles (id, label, tracking, route_mode, lane_x, start_x, start_y, phase)
values
  ('v1', 'Ajoneuvo 1 (kunnossapito)', 'app', 'taxiway', 398, 370, 372, 'apron'),
  ('v2', 'Ajoneuvo 2 (maahuolinta)', 'app', 'taxiway', 412, 440, 380, 'apron')
on conflict (id) do nothing;

-- Realtime: ilman tätä muutokset eivät välity live-tilassa muille selaimille
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'efet_vehicles') then
    alter publication supabase_realtime add table efet_vehicles;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'efet_world_state') then
    alter publication supabase_realtime add table efet_world_state;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'efet_log') then
    alter publication supabase_realtime add table efet_log;
  end if;
end $$;
