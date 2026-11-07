import { assertEquals } from "jsr:@std/assert@1";

import { FakeProvider } from "./ai/index.ts";
import { defaults } from "./config.ts";
import { createRaidDraft, joinRaidDraft } from "./create_raid.ts";
import { endDraft } from "./end_session.ts";
import { resolveRaidsDraft } from "./raid_resolve.ts";

const alice = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
const bob = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb";
const raidId = "cccccccc-cccc-cccc-cccc-cccccccccccc";
const taskAlice = "dddddddd-dddd-dddd-dddd-dddddddddddd";
const taskBob = "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee";
const sessionAlice = "11111111-1111-1111-1111-111111111111";
const sessionBob = "22222222-2222-2222-2222-222222222222";
const createdAt = new Date("2026-10-10T08:00:00.000Z");
const deadline = "2026-10-12T12:00:00.000Z";
const resolveAt = new Date("2026-10-12T12:00:01.000Z");

type Row = Record<string, unknown>;

Deno.test("two-account party raid: damage ticker, fair share checks and MVP", async () => {
  const state = {
    raid: null as Row | null,
    members: [] as Row[],
    damage: new Map<string, number>(),
    events: [] as Row[],
    inbox: [] as Row[],
    sessionsProcessed: new Set<string>(),
  };

  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join("?");

    if (text.includes("from bosses") && text.includes("count")) return Promise.resolve([{ n: 0 }]);
    if (text.includes("from raid_members rm") || (text.includes("join raids r") && text.includes("count"))) {
      return Promise.resolve([{ n: 0 }]);
    }
    if (text.includes("from player_state") && text.includes("ai_calls")) {
      return Promise.resolve([{ ai_calls_today: 0 }]);
    }
    if (text.includes("from user_settings")) return Promise.resolve([{ study_context: null, demo_mode: false }]);
    if (text.includes("from demo_allowlist")) return Promise.resolve([]);
    if (text.includes("from profiles")) {
      const uid = String(values[0] ?? alice);
      return Promise.resolve([{
        display_name: uid === bob ? "Bob" : "Alice",
        equipped_skin_id: "skin_starter",
        equipped_frame_id: "frame_apprentice",
        body_type: "a",
        title_id: null,
      }]);
    }
    if (text.includes("select 1 from raids where invite_code")) return Promise.resolve([]);
    if (text.includes("insert into raids")) {
      state.raid = {
        id: raidId,
        source: "party",
        guild_id: null,
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
        created_at: createdAt,
      };
      return Promise.resolve([state.raid]);
    }
    if (text.includes("insert into raid_members")) {
      const userId = String(values[1]);
      const existing = state.members.find((m) => m.user_id === userId);
      if (existing) {
        existing.left_raid = false;
      } else {
        state.members.push({
          raid_id: raidId,
          user_id: userId,
          display_name: userId === bob ? "Bob" : "Alice",
          left_raid: false,
          met_fair_share: false,
          is_mvp: false,
        });
      }
      return Promise.resolve([]);
    }
    if (text.includes("insert into raid_damage") && text.includes("on conflict")) {
      const userId = String(values[1]);
      const amount = Number(values[2]);
      state.damage.set(userId, amount);
      return Promise.resolve([]);
    }
    if (text.includes("insert into raid_damage")) {
      const userId = String(values[1]);
      if (!state.damage.has(userId)) state.damage.set(userId, 0);
      return Promise.resolve([]);
    }
    if (text.includes("from raids where upper(invite_code)") || (text.includes("from raids where id") && text.includes("for update"))) {
      return Promise.resolve(state.raid ? [state.raid] : []);
    }
    if (text.includes("from raids") && text.includes("status = 'active'") && text.includes("deadline")) {
      return Promise.resolve(state.raid && state.raid.status === "active" ? [state.raid] : []);
    }
    if (text.includes("from raids") && text.includes("status = 'active'") && text.includes("for update")) {
      return Promise.resolve(state.raid && state.raid.status === "active" ? [{
        id: raidId,
        status: "active",
        damage: state.raid.damage,
        max_hp: state.raid.max_hp,
        participants: state.raid.participants,
      }] : []);
    }
    if (text.includes("select user_id, display_name, left_raid from raid_members")) {
      return Promise.resolve(state.members);
    }
    if (text.includes("select left_raid from raid_members")) {
      const userId = String(values[1] ?? values[0]);
      const member = state.members.find((m) => m.user_id === userId);
      return Promise.resolve(member ? [{ left_raid: member.left_raid }] : []);
    }
    if (text.includes("select display_name, left_raid from raid_members")) {
      const userId = String(values[1]);
      const member = state.members.find((m) => m.user_id === userId);
      return Promise.resolve(member ? [{ display_name: member.display_name, left_raid: member.left_raid }] : []);
    }
    if (text.includes("select count(*)") && text.includes("left_raid = false")) {
      return Promise.resolve([{ n: state.members.filter((m) => !m.left_raid).length }]);
    }
    if (text.includes("from raid_members where raid_id")) {
      return Promise.resolve(state.members);
    }
    if (text.includes("from raid_damage")) {
      if (text.includes("for update")) {
        const userId = String(values[1]);
        return Promise.resolve([{ damage: state.damage.get(userId) ?? 0 }]);
      }
      return Promise.resolve([...state.damage.entries()].map(([user_id, damage]) => ({ user_id, damage })));
    }
    if (text.includes("update raids set damage")) {
      if (state.raid) state.raid.damage = values[0];
      return Promise.resolve([]);
    }
    if (text.includes("insert into raid_events")) {
      state.events.push({
        raid_id: values[0],
        user_id: values[1],
        display_name: values[2],
        amount: values[3],
      });
      return Promise.resolve([]);
    }
    if (text.includes("update raid_members set") && text.includes("met_fair_share")) {
      const userId = String(values[values.length - 1]);
      const member = state.members.find((m) => m.user_id === userId);
      if (member) {
        member.met_fair_share = values[0] === true;
        if (text.includes("is_mvp")) member.is_mvp = values[1] === true;
      }
      return Promise.resolve([]);
    }
    if (text.includes("update raids set status")) {
      if (state.raid) state.raid.status = values[0];
      return Promise.resolve([]);
    }
    if (text.includes("delete from raid_events")) {
      state.events = [];
      return Promise.resolve([]);
    }
    if (text.includes("insert into inbox")) {
      const type = text.includes("'raid_result'")
        ? "raid_result"
        : text.includes("'guild_fight'")
        ? "guild_fight"
        : String(values[1] ?? "system");
      const payload = type === "raid_result" ? values[1] : values[2];
      state.inbox.push({ user_id: values[0], type, payload });
      return Promise.resolve([]);
    }
    if (text.includes("from player_state") && text.includes("for update")) {
      return Promise.resolve([{
        timezone: "Asia/Colombo",
        focus_minutes_today: 0,
        weekly_raw_xp: 0,
        week_id: "2026-W41",
        xp_total: 200,
        comeback_armed: false,
        potions: 0,
        onboarding_step: "done",
        coins: 300,
        boss_coins_this_week: 0,
      }]);
    }
    if (text.includes("from sessions")) {
      const id = String(values[0]);
      const user = String(values[1]);
      return Promise.resolve([{
        id,
        task_id: user === bob ? taskBob : taskAlice,
        mode: "focus",
        started_at: new Date(createdAt.getTime() - 60 * 60 * 1000).toISOString(),
        status: "active",
        potion: false,
        processed: state.sessionsProcessed.has(id),
        summary: null,
      }]);
    }
    if (text.includes("from tasks")) {
      const taskId = String(values[0]);
      return Promise.resolve([{
        difficulty: 4,
        est_minutes: 60,
        stat: "intellect",
        due_at: deadline,
        rescheduled: false,
        scroll_used: false,
        status: "open",
        boss_id: null,
        raid_id: raidId,
        id: taskId,
      }]);
    }
    if (text.includes("from inventory") || text.includes("from level_rewards") || text.includes("from guild_members")) {
      return Promise.resolve([]);
    }
    if (text.includes("update sessions") && text.includes("processed = true")) {
      state.sessionsProcessed.add(String(values.find((v) => typeof v === "string" && v.includes("-")) ?? ""));
      // values order varies; mark by session id in query values
      for (const value of values) {
        if (value === sessionAlice || value === sessionBob) state.sessionsProcessed.add(String(value));
      }
      return Promise.resolve([]);
    }
    return Promise.resolve([]);
  };

  const created = await createRaidDraft(
    alice,
    {
      source: "party",
      title: "Systems project",
      type: "project",
      deadline,
      participants: 2,
      perPersonHours: 6,
      name: "The Practice Shade",
      dryRun: false,
    },
    tx,
    new FakeProvider(),
    defaults,
    createdAt,
  );
  assertEquals("raid" in created, true);
  if (!("raid" in created)) return;
  assertEquals(created.raid.maxHp, 720);
  assertEquals(state.members.length, 1);

  await joinRaidDraft(bob, { code: String(state.raid?.invite_code) }, tx, defaults);
  assertEquals(state.members.length, 2);

  const aliceEnd = await endDraft(alice, { sessionId: sessionAlice, interruptions: [] }, tx, defaults, createdAt);
  const bobEnd = await endDraft(bob, { sessionId: sessionBob, interruptions: [] }, tx, defaults, createdAt);
  assertEquals(aliceEnd.raidDamage, 60);
  assertEquals(bobEnd.raidDamage, 60);
  assertEquals(state.events.length, 2);
  assertEquals(Number(state.raid?.damage), 120);

  // Top up damage so Alice meets fair share (180) and is MVP.
  state.damage.set(alice, 400);
  state.damage.set(bob, 320);
  state.raid!.damage = 720;

  const resolved = await resolveRaidsDraft(tx, defaults, resolveAt, () => 0.99);
  assertEquals(resolved, 1);
  assertEquals(state.raid?.status, "victory");
  assertEquals(state.events.length, 0);

  const results = state.inbox
    .filter((row) => row.type === "raid_result")
    .map((row) => JSON.parse(String(row.payload)) as {
      metFairShare: boolean;
      isMvp: boolean;
      result: string;
    });
  assertEquals(results.length, 2);
  assertEquals(results.every((row) => row.result === "victory"), true);
  assertEquals(results.every((row) => row.metFairShare === true), true);
  assertEquals(results.filter((row) => row.isMvp).length, 1);
});
