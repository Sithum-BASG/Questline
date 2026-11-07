-- Schedule deadline resolver every 15 minutes (schema §6).
-- Vault secrets `project_url` and `cron_secret` must be set in the cloud project.

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

do $$
begin
  perform cron.unschedule(jobid)
  from cron.job
  where jobname = 'deadlines-15m';
exception
  when undefined_table then null;
  when undefined_function then null;
end $$;

select cron.schedule(
  'deadlines-15m',
  '*/15 * * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url')
           || '/functions/v1/cron-deadlines',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'cron_secret')
    ),
    body := '{}'::jsonb
  );
  $$
);
