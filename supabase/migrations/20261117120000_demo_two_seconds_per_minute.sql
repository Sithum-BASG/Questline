-- T173: demo mode counts 2 seconds as 1 focus minute (10 seconds per 5 minutes).
update game_config set value = '10'::jsonb where key = 'demo_seconds_per_5_minutes';
