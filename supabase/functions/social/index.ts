import {
  removeFriend,
  respondFriendRequest,
  sendFriendRequest,
} from "../_shared/friend_actions.ts";
import { createGuild, joinGuild, leaveGuild } from "../_shared/guild_actions.ts";
import { dispatch } from "../_shared/router.ts";

export const handle = dispatch({
  sendFriendRequest: (body, user) => sendFriendRequest(user.id, body),
  respondFriendRequest: (body, user) => respondFriendRequest(user.id, body),
  removeFriend: (body, user) => removeFriend(user.id, body),
  createGuild: (body, user) => createGuild(user.id, body),
  joinGuild: (body, user) => joinGuild(user.id, body),
  leaveGuild: (body, user) => leaveGuild(user.id, body),
});

if (import.meta.main) Deno.serve(handle);
