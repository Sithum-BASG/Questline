-- T164: objects stored as JSON strings are unwrapped; everything else is left alone.
BEGIN;
SELECT plan(6);

SELECT is(public.unwrap_jsonb_string(to_jsonb('{"raid_mvps":2}'::text)), '{"raid_mvps":2}'::jsonb,
  'an object stored as a JSON string becomes the object');
SELECT is(public.unwrap_jsonb_string(to_jsonb('[1,2]'::text)), '[1,2]'::jsonb,
  'an array stored as a JSON string becomes the array');
SELECT is(public.unwrap_jsonb_string('{"a":1}'::jsonb), '{"a":1}'::jsonb, 'objects are unchanged');
SELECT is(public.unwrap_jsonb_string(to_jsonb('hello'::text)), to_jsonb('hello'::text), 'plain strings are unchanged');
SELECT is(public.unwrap_jsonb_string(to_jsonb('42'::text)), to_jsonb('42'::text), 'strings holding scalars are unchanged');
SELECT is(public.unwrap_jsonb_string(NULL), NULL, 'null stays null');

SELECT * FROM finish();
ROLLBACK;
