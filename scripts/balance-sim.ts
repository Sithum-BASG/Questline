/**
 * Prints the Phase 15 balance simulation (2 h/day, 6 days/week, 12 weeks).
 * Run: deno run scripts/balance-sim.ts
 */
import { runBalanceSimulation } from "../supabase/functions/_shared/game/balance_simulation.ts";

const result = runBalanceSimulation();
console.log(JSON.stringify(result, null, 2));
