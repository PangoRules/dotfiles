---
name: signalr-verification
description: Use when a diff touches SignalR hubs, hub methods, hub events, or client-side SignalR connection code — verifies hub registration, method signatures, and real-time event contracts before LGTM.
---

# SignalR Verification

SignalR bugs are silent at build time and only surface at runtime when events don't fire or clients don't receive them. Run this before LGTM on any hub-touching diff.

## Step 1 — Build

```bash
dotnet build
```

Hub registration errors (missing `AddSignalR()`, wrong route) surface here.

## Step 2 — Hub route registration

Confirm hubs are still mapped in your startup/program file:

```bash
grep -rn "MapHub" src/ --include="*.cs"
```

Expected: all hubs present, routes unchanged unless the diff intentionally moved them.

## Step 3 — Method signature contract check

If the diff adds, renames, or removes hub methods or client-callable methods:

```bash
# Server-side hub methods
grep -rn "public.*Task\|public.*void" src/ --include="*.cs" | grep -i hub

# Client invocations (TypeScript/JavaScript)
grep -rn "\.invoke\|\.on(" src/ --include="*.ts" --include="*.vue" --include="*.tsx" --include="*.js"
```

Cross-check: every `HubConnection.invoke("MethodName")` on the client must match a public method on the server hub. Every `HubConnection.on("EventName")` must match a `Clients.*.SendAsync("EventName")` on the server. Name mismatches fail silently — the client just never receives the event.

## Step 4 — Group membership (if touched)

If the diff touches any group join/leave logic:

```bash
grep -rn "AddToGroupAsync\|RemoveFromGroupAsync" src/ --include="*.cs"
```

Confirm the group name used in `SendAsync` matches the group name used in `AddToGroupAsync`. Typo = silent broadcast failure to the entire group.

## Step 5 — Integration tests (if any)

```bash
dotnet test --filter "SignalR|Hub|Realtime"
```

If no tests match, note it — real-time paths are untested. Flag as a finding if the diff adds hub logic without adding a test.

## Step 6 — Manual smoke (for hub logic changes)

If the diff changes what triggers a broadcast or what data is sent:

1. Start the server
2. Open two browser tabs or clients connected to the same hub group
3. Trigger the changed action in one client
4. Verify the other client receives the event (browser DevTools → Network → WS → filter by hub route)

## Reviewer note

`dotnet test` passing does not prove hub events fire — xUnit tests don't exercise SignalR groups or real-time delivery by default. Steps 3 and 6 are the only real checks for event contract correctness. If a diff touches hub broadcast logic and Step 6 was not run, that is a finding.

## Common silent failures

| Mistake | Symptom | Cause |
|---------|---------|-------|
| Client calls `invoke("sendMessage")`, server has `SendMessage` | Nothing happens | C# is case-sensitive on hub method names via reflection; SignalR lowercases by default — match the casing convention |
| Group name typo in `AddToGroupAsync` vs `SendAsync` | Broadcast never arrives | Silent — no error thrown |
| Missing `await Groups.AddToGroupAsync` | Client in group but never receives | Race condition or missing call |
| Hub method returns `void` instead of `Task` | Concurrent callers block | Hub methods must be `async Task` |
