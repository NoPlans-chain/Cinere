# Repository Guidelines

## Project Structure & Module Organization
**Ex Cinere** is a proximity-based social survival RPG and political economy simulation built on Bluetooth Low Energy (BLE) technology.
- **Core Mechanic**: Proximity-based bonding and chain building. No GPS is used.
- **Simulation Layer**: A living macroeconomy featuring sovereign currencies (Valuables), commodity receipts, and encrypted syndicate scrip (Cipher).
- **Frontend**: React/Vite SPA utilizing TailwindCSS for a terminal-inspired aesthetic (navy, burnt orange, maroon).
- **Backend**: Supabase manages authoritative state, realtime synchronization, and persistence.
- **Tick Engine**: A Node.js worker that executes the global economic simulation.
- **Hardcore Mode**: Permanent death for survivors; player level resets to 1, while reputation and camp structures persist.

## Build, Test, and Development Commands
*Note: This repository currently contains design specifications. Implementation commands will be added as the foundation is established.*
- **Planned Stack**:
  - Frontend: `npm run dev` (Vite)
  - Backend: Supabase CLI for migrations and edge functions.
  - Worker: Node.js scripts for the tick engine.

## Coding Style & Naming Conventions
Strict adherence to the **LLM Development Protocol** is mandatory for all code generation:
- **No Placeholder Data**: Hardcoded values are forbidden; all data must originate from Supabase.
- **Deterministic Systems**: Logic must ensure that the same state and seed always produce the same outcome.
- **Type Safety**: TypeScript (inferred) is required to avoid undefined states and ensure reliable system behavior.
- **Async Safety**: Implement rigorous checks to prevent race conditions during tick execution.
- **Visual Identity**: Near-black navy background, burnt orange text, and maroon panels (Terminal aesthetic).

## Testing Guidelines
- **System Isolation**: Every new system must be independently testable.
- **Validation**: Every generated system must include error handling, console logging, and DB validation.
- **Empty State Handling**: Components must handle missing data gracefully without crashing.

## Architecture & Simulation Rules
- **Tick Sequence**: The engine must follow a specific sequence: State Load -> Production -> AI Decisions -> Order Aggregation -> Price Formation -> Funding -> Trade Execution -> Portfolio Updates -> Macro Updates -> Persistence.
- **AI Constraints**: Autonomous traders must operate with bounded capital and imperfect information, storing state between ticks.
- **Hardcore Mortality**: Level 1-99 progression. Death resets level but preserves reputation, infamy, and camp upgrades.
