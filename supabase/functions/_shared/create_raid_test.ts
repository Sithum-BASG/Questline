import { assertEquals, assertRejects } from "jsr:@std/assert@1";

import { FakeProvider } from "./ai/index.ts";
import { defaults } from "./config.ts";
import { AppError } from "./errors.ts";
import {
  createRaidDraft,
  joinRaidDraft,
  leaveRaidDraft,
} from "./create_raid.ts";

const userId = "11111111-1111-1111-1111-111111111111";
const guildId = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
const raidId = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb";
const now = new Date("2026-10-10T10:00:00.000Z");
const deadline = "2026-10-13T10:00:00.000Z";

function scripted(options: {
  inGuild?: boolean;
  soloCount?: number;
  raidCount?: number;
  aiCalls?: number;
  raid?: Record<string, unknown> | null;
  memberCount?: number;
  alreadyMember?: boolean;
  leftRaid?: boolean;
} = {}) {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join("?");
    queries.push({ text, values });

    if (text.includes("from guild_members") && text.includes("guild_id =")) {
      return Promise.resolve(options.inGuild === false ? [] : [{ guild_id: guildId }]);
    }
    if (text.includes("from bosses") && text.includes("count")) {
      return Promise.resolve([{ n: options.soloCount ?? 0 }]);
    }
    if (text.includes("from raid_members rm") || (text.includes("join raids r") && text.includes("count"))) {
      return Promise.resolve([{ n: options.raidCount ?? 0 }]);
    }
    if (text.includes("from player_state")) {
      return Promise.resolve([{ ai_calls_today: options.aiCalls ?? 0 }]);
    }
    if (text.includes("from user_settings")) {
      return Promise.resolve([{ study_context: null }]);
    }
    if (text.includes("from profiles")) {
      return Promise.resolve([{
        display_name: "Me",
        equipped_skin_id: "skin_starter",
        equipped_frame_id: "frame_apprentice",
        body_type: "a",
        title_id: null,
      }]);
    }
    if (text.includes("insert into raids")) {
      return Promise.resolve([{
        id: raidId,
        source: values[0],
        guild_id: values[1],
        name: values[2],
        title: values[3],
        type: values[4],
        tier: values[5],
        per_person_minutes: values[6],
        participants: values[7],
        max_hp: values[8],
        damage: 0,
        deadline: values[10],
        status: "active",
        created_by: values[12],
        invite_code: values[13],
        coins_eligible: values[14],
        created_at: now,
      }]);
    }
    if (text.includes("from raids where upper(invite_code)") || text.includes("from raids where id")) {
      if (options.raid === null) return Promise.resolve([]);
      return Promise.resolve([options.raid ?? {
        id: raidId,
        source: "party",
        guild_id: null,
        name: "The Practice Shade",
        title: "Group project",
        type: "project",
        tier: "brute",
        per_person_minutes: 360,
        participants: 4,
        max_hp: 1440,
        damage: 0,
        deadline,
        status: "active",
        created_by: userId,
        invite_code: "ABCD1234",
        coins_eligible: true,
        created_at: now,
      }]);
    }
    if (text.includes("select left_raid from raid_members")) {
      if (!options.alreadyMember && options.leftRaid == null) return Promise.resolve([]);
      return Promise.resolve([{ left_raid: options.leftRaid ?? false }]);
    }
    if (text.includes("count(*)") && text.includes("from raid_members") && text.includes("left_raid")) {
      return Promise.resolve([{ n: options.memberCount ?? 1 }]);
    }
    if (text.includes("select 1 from raids where invite_code")) {
      return Promise.resolve([]);
    }
    return Promise.resolve([]);
  };
  return { tx, queries };
}

const baseBody = {
  title: "Group systems project",
  type: "project" as const,
  deadline,
  participants: 4,
};

Deno.test("dryRun returns a raid preview using per-person hours", async () => {
  const { tx, queries } = scripted();
  const result = await createRaidDraft(
    userId,
    { ...baseBody, source: "party", dryRun: true },
    tx,
    new FakeProvider(),
    defaults,
    now,
  );
  assertEquals("preview" in result, true);
  if (!("preview" in result)) return;
  assertEquals(result.preview.perPersonHours, 6);
  assertEquals(result.preview.maxHp, 6 * 60 * 4);
  assertEquals(result.preview.participants, 4);
  assertEquals(queries.some((q) => q.text.includes("insert into raids")), false);
});

Deno.test("createRaid party writes invite code and joins the creator", async () => {
  const { tx, queries } = scripted();
  const result = await createRaidDraft(
    userId,
    {
      ...baseBody,
      source: "party",
      dryRun: false,
      perPersonHours: 6,
      name: "The Practice Shade",
    },
    tx,
    new FakeProvider(),
    defaults,
    now,
  );
  assertEquals("raid" in result, true);
  if (!("raid" in result)) return;
  assertEquals(result.raid.source, "party");
  assertEquals(result.raid.maxHp, 1440);
  assertEquals(queries.some((q) => q.text.includes("insert into raid_members")), true);
  assertEquals(queries.some((q) => q.text.includes("insert into raid_damage")), true);
});

Deno.test("createRaid guild fight notifies other members", async () => {
  const { tx, queries } = scripted({ inGuild: true });
  await createRaidDraft(
    userId,
    {
      ...baseBody,
      source: "guild",
      guildId,
      dryRun: false,
      perPersonHours: 4,
      name: "The Guild Shade",
    },
    tx,
    new FakeProvider(),
    defaults,
    now,
  );
  assertEquals(queries.some((q) => q.text.includes("guild_fight")), true);
});

Deno.test("joinRaid refuses a full party", async () => {
  const { tx } = scripted({ memberCount: 4, alreadyMember: false });
  await assertRejects(
    () => joinRaidDraft(userId, { code: "ABCD1234" }, tx, defaults),
    AppError,
  );
});

Deno.test("leaveRaid marks left_raid without clearing damage", async () => {
  const { tx, queries } = scripted({ alreadyMember: true, leftRaid: false });
  const result = await leaveRaidDraft(userId, { raidId }, tx);
  assertEquals(result.ok, true);
  assertEquals(queries.some((q) => q.text.includes("left_raid = true")), true);
  assertEquals(queries.some((q) => q.text.includes("delete from raid_damage")), false);
});
