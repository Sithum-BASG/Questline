-- Schedule hourly rollover via pg_cron → pg_net → Edge Function (schema §6).
-- Vault secrets `project_url` and `cron_secret` must be set in the cloud project.
-- If pg_cron is unavailable on Free, use .github/workflows/cron.yml instead.

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

-- Idempotent: unschedule any previous job with the same name, then schedule.
do $$
begin
  perform cron.unschedule(jobid)
  from cron.job
  where jobname = 'rollover-hourly';
exception
  when undefined_table then null;
  when undefined_function then null;
end $$;

select cron.schedule(
  'rollover-hourly',
  '0 * * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url')
           || '/functions/v1/cron-rollover',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'cron_secret')
    ),
    body := '{}'::jsonb
  );
  $$
);
