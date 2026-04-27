---
name: test-failure-diagnosis
description: Use before investigating a test assertion failure — forces proving the code path runs before investigating values
---

# Test Failure Diagnosis

## The Rule

When a test assertion fails with `expected undefined to be truthy`, `expected null to equal X`, or any assertion where the received value is `undefined` or `null`:

**Do NOT investigate the value. First prove the code path ran.**

## Why

`undefined` almost always means the code path that was supposed to produce the value never executed — not that it produced the wrong value. Investigating the wrong thing is how agents loop for 10 iterations without converging.

## The Mandatory First Step

Before reading any implementation code, add a log at the entry point of the suspected handler and re-run the test:

```ts
// Temporary — remove after diagnosis
const handleSubmit = async () => {
  console.log("[DEBUG] handleSubmit called");
  // ... rest of handler
};
```

Run the test. Read the output.

**If the log does NOT appear:** The handler is never called. The issue is event wiring — the event that should trigger the handler is not reaching it. Do not investigate the handler's internals. Investigate why the event is not firing.

**If the log DOES appear:** The handler runs. The issue is in what it does — wrong value, wrong condition, async timing. Now investigate the implementation.

Remove the debug log before committing.

## Common Event Wiring Causes

When the handler is never called in a test environment:

- **Form submit via button click**: `@submit.prevent` on the form only fires when the form's native `submit` event fires. In happy-dom and JSDOM, `trigger("click")` on a `type="submit"` button does NOT propagate to the form's submit event. Fix: add `@click` directly on the button, or `trigger("submit")` on the form in the test.
- **Event name mismatch**: Component emits `"item-added"`, test asserts `emitted("added")`. Check exact string match.
- **Wrong element selected**: `find('button[type="submit"]')` finds nothing if the button has a different type or the selector is wrong. Add `console.log(wrapper.html())` to see what the DOM actually looks like.
- **Async handler not awaited**: If the handler is async and the test doesn't await DOM updates after trigger, the assertion runs before the emit. Add `await nextTick()` after trigger.

## After Diagnosis

Once you know whether the code path ran or not, continue with `systematic-debugging` Phase 3 (hypothesis and testing). The diagnosis step replaces Phase 1 "Gather Evidence" for test assertion failures — don't repeat the instrumentation phase, proceed directly to the hypothesis.
