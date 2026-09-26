# Project

This is a Roblox game using Roblox Studio, Luau, Rojo 7, Git, and Codex.
The project includes a minimal server-generated platform map. Extend gameplay
or map systems only within the requested scope.

## Architecture

- `src/server` contains code that runs exclusively on the server.
- `src/client` contains client code.
- `src/shared` contains ModuleScripts shared by the client and server.
- Prefer small, focused ModuleScripts over large monolithic scripts.
- Separate configuration from implementation.
- Do not create unnecessarily large individual files.
- Shared modules are visible to clients; never put secrets in them.

## Roblox

- Use Luau and Roblox APIs instead of generic Lua patterns when Roblox provides
  an appropriate API.
- Retrieve services with `game:GetService()`.
- Never trust data sent by the client.
- Validate RemoteEvent and RemoteFunction arguments on the server, including
  permissions, ranges, and request frequency where appropriate.
- Keep gameplay-critical logic under server control.
- Avoid unnecessary RunService connections and per-frame loops.
- Clean up event connections and created instances when they are no longer needed.
- Do not use deprecated Roblox APIs when a modern replacement exists.

## Map development

The project will grow into a large Roblox map. For future map-related code:

- Use `Workspace/Map` as the main container for map elements created by code.
- Keep map configuration out of large generators; put parameters in configuration
  modules.
- Give procedurally created instances readable names.
- Prefer deterministic generation when a seed is used.
- Support removing and regenerating the generated map without deleting unrelated
  Studio-authored content.
- Avoid generating huge numbers of Parts unnecessarily.
- Consider CollectionService tags for objects belonging to specific categories.
- Keep map generation in `src/server/MapGenerator.luau` and its parameters in
  `src/shared/ObbyConfig.luau`. Geometry helpers live in `ObbyParts.luau` and
  server checkpoint/kill/finish logic in `ObbySession.luau`.
- Generated children of `Workspace/Map` carry the `ObbyGenerated` attribute.
  Regeneration disconnects the previous session, removes generated objects,
  and resets players to the start. Preserve unrelated user objects.
- Math problems and numeric answers belong to `MathProblemGenerator.luau`;
  `MathGateGenerator.luau` builds the section and `MathGateTriggers.luau` handles
  server touches. Parameters live in `src/shared/MathConfig.luau`.
- RoundManager owns the optional `ObbyConfig.Seed` random stream and advances it
  across rounds. Problems remain fixed within a round. Keep debounce per player
  and door, and use the existing ObbySession respawn/checkpoint system.
- RoundManager owns rewards, CurrentRound, completion by UserId, and one countdown.
  ObbySession validates finish touches and keeps checkpoint/respawn ownership.
  PlayerStats owns session-only leaderstats. Never award from client code.
- Use RoundManager.nextRound() for manual regeneration during play. The public
  MapGenerator.generate()/Generate() methods route through it; build() is internal
  to the round flow. Invalidate old callbacks and timers before changing maps.
- RoundStateEvent only sends server state to clients. Keep the revisioned player
  snapshot for late GUI initialization and never accept client completion claims.

## Rojo

- Preserve the mappings in `default.project.json`:
  - `src/server` -> `ServerScriptService/Server`
  - `src/client` -> `StarterPlayer/StarterPlayerScripts/Client`
  - `src/shared` -> `ReplicatedStorage/Shared`
- Check compatibility with the Rojo configuration before changing folder structure.
- Keep `.luau` extensions consistent; entry points use `.server.luau` and
  `.client.luau`, and shared ModuleScripts use `.luau`.
- Do not map Workspace without an explicit decision to manage map content in Rojo.
  Initially the map is created and edited in Roblox Studio.
- Do not edit generated `.rbxl` files as source code.
- Keep source code in the repository. Edit synchronized scripts in source files.
- Use Roblox Studio to run, visually edit, and test the game.

## Testing

After significant changes:

- Check Luau syntax using available tools and Studio Script Analysis.
- Check Roblox service names.
- Check client/server boundaries.
- Check that remote handlers validate requests on the server.
- Validate project JSON and mapped paths when changing Rojo configuration.
- If Rojo is available, run a build to a temporary output and remove that output.
  A Rojo build checks synchronization structure, not Luau syntax or runtime behavior.
- Explain how to test the change in Roblox Studio, including expected results.
- Report unavailable checks honestly; do not claim unperformed tests passed.

## Codex behavior

- Inspect the existing project structure before starting a significant change.
- Do not remove existing functionality without a clear need.
- Preserve current game behavior during refactoring.
- Split larger systems into logical modules.
- After completing a task, briefly summarize created or modified files.
- Clearly identify any manual Roblox Studio operations required for the change.
