-- RIAS – oikeuskorjaus (aja skeeman jälkeen Supabasen SQL Editorissa)
-- Syy: RLS-säännöt eivät riitä, jos anon-roolilla ei ole taulutason perusoikeuksia.
-- Ilman näitä selain saa virheen "permission denied for table ...".

grant usage on schema public to anon;

grant select, update on world_state to anon;
grant select, insert, update, delete on vehicles to anon;
grant select, insert on log to anon;

-- log.id on bigserial, joten insert tarvitsee oikeuden sen juoksevaan numeroon
grant usage, select on sequence log_id_seq to anon;

-- Demon Reset-painike poistaa ylimääräiset ajoneuvot, joten delete-sääntö tarvitaan myös RLS:ssä
create policy "anon delete vehicles" on vehicles for delete using (true);
