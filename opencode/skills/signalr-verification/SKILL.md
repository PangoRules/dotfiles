---
name: signalr-verification
description: Use when a diff touches SignalR hubs, hub methods, hub events, or client-side SignalR connection code — verifies hub registration, method signatures, and real-time event contracts before LGTM.
---

# SignalR Verification

Hydra-forge has two hubs:
- **BoardHub** at `/hubs/board` — `JoinProject`, `LeaveProject`, `OnBoardEvent`
- **PresenceHub** — `JoinProject`, `FocusCard`, `UserJoined`, `UserLeft`, `CardFocused`

SignalR bugs are silent at build time and only surface at runtime when events don't fire or clients don't receive them. Run this before LGTM on any hub-touching diff.

## Step 1 — Build

```bash
dotnet build
```

Hub registration errors (missing `AddSignalR()`, wrong route) surface here.

## Step 2 — Hub route registration

Confirm hubs are still mapped in `Program.cs` (or wherever `app.MapHub<T>` is called):

```bash
grep -n "MapHub" src/Server/Program.cs
```

Expected: both hubs present, routes unchanged unless the diff intentionally moved them.

## Step 3 — Method signature contract check

If the diff adds, renames, or removes hub methods or client-callable methods:

```bash
# Server hub methods
grep -n "public.*Task\|public.*void" src/Server/Hubs/*.cs

# Client invocations (TypeScript)
grep -rn "\.invoke\|\.on(" src/web-ui/app/ --include="*.ts" --include="*.vue"
```

Cross-check: every `HubConnection.invoke("MethodName")` on the client must match a public method on the server hub. Every `HubConnection.on("EventName")` must match a `Clients.Caller.SendAsync("EventName")` / `Clients.Group(...).SendAsync("EventName")` on the server. Name mismatches fail silently — the client just never receives the event.

## Step 4 — Group membership (if touched)

If the diff touches `JoinProject` / `LeaveProject` or any `Groups.AddToGroupAsync` call:

```bash
grep -n "AddToGroupAsync\|RemoveFromGroupAsync" src/Server/Hubs/*.cs
```

Confirm the group name used in `SendAsync` matches the group name used in `AddToGroupAsync`. Typo = silent broadcast failure.

## Step 5 — Integration tests (if any)

```bash
dotnet test --filter "SignalR|Hub|Realtime"
```

If no tests match, note it — real-time paths are untested. Flag as a finding if the diff adds hub logic without adding a test.

## Step 6 — Manual smoke (for hub logic changes)

If the diff changes what triggers a broadcast or what data is sent:

1. Start server: `dotnet run --project src/Server`
2. Open two browser tabs on the same board
3. Trigger the changed action in tab A
4. Verify tab B receives the event (browser DevTools → Network → WS → filter by hub route)

For PresenceHub changes: open two tabs, focus a card in one, verify the other tab shows the presence indicator update.

## Reviewer note

`dotnet test` passing does not prove hub events fire — xUnit tests don't exercise SignalR groups or real-time delivery by default. Steps 3 and 6 are the only real checks for event contract correctness. If a diff touches hub broadcast logic and Step 6 was not run, that is a finding.
