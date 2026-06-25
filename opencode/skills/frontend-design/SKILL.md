---
name: frontend-design
description: Use when building or redesigning any UI — Nuxt 4, Vue components, Spectre.Console TUI, or any frontend surface. Prevents generic AI-templated aesthetics; forces deliberate design decisions before writing code.
---

# Frontend Design

Approach this as the design lead at a small studio known for giving every client a visual identity that could not be mistaken for anyone else's. Make deliberate, opinionated choices about palette, typography, and layout specific to this brief. Take one real aesthetic risk you can justify.

## Ground it in the subject

If the brief does not pin down what the product or subject is, pin it yourself before designing: name one concrete subject, its audience, and the page's single job. The subject's own world — its materials, instruments, artifacts, and vernacular — is where distinctive choices come from. Build with the brief's real content and subject matter throughout.

## Design principles

**Hero is a thesis.** Open with the most characteristic thing in the subject's world. A big number with a small label and a gradient accent is the template answer — only use if it's truly the best option.

**Typography carries personality.** Pair display and body faces deliberately, not the same families you would reach for on any other project. Set a clear type scale with intentional weights, widths, and spacing.

**Structure is information.** Numbered markers (01 / 02 / 03) are only appropriate if the content actually is a sequence. Question every structural device before using it.

**Motion serves the subject.** Choose animation deliberately: page-load sequence, scroll-triggered reveal, hover micro-interactions, ambient atmosphere. An orchestrated moment lands harder than scattered effects. Too much animation makes it feel AI-generated.

**Match complexity to vision.** Maximalist directions need elaborate execution; minimal directions need precision in spacing, type, and detail.

## For Spectre.Console TUI surfaces

Spectre.Console's constraint is the canvas — no web fonts, no CSS, only what the terminal allows. Design principles still apply:

- **Color palette**: pick 3–4 named Color enum values and use them consistently across panels, rules, and prompts. Don't use every color Spectre offers.
- **Layout rhythm**: Panel/Table borders create structure — choose one border style and stick to it. Mixed border styles read as unfinished.
- **Information density**: Terminals favor dense output. Use markup sparingly (`[bold]`, `[green]`, `[dim]`) — decorating everything decorates nothing.
- **Signature element**: one distinctive output moment the user will remember (a progress bar sequence, a summary panel layout, a specific color for errors).

## Process: brainstorm, plan, critique, build, critique again

**Pass 1 — Design plan** (before writing any code):

Create a compact token system:
- **Color**: 4–6 named hex values (web) or Color enum values (TUI)
- **Type**: roles for display, body, and utility faces (web) or markup styles (TUI)
- **Layout**: one-sentence prose description + ASCII wireframe
- **Signature**: the single unique element this will be remembered by

**Pass 2 — Self-critique before building**:

Check the plan against these failure modes:
1. Does it read like a template answer you would produce for any similar brief?
2. Would a different brief for a similar product produce the same plan?
3. Is the signature element actually distinctive or just decoration?

If any answer is yes, revise that part. State what you changed and why. Only after confirming the plan's distinctiveness should you write the code.

## Restraint and self-critique

Spend boldness in one place. The signature element is the one memorable thing — keep everything around it quiet and disciplined. Cut decoration that does not serve the brief.

Build to a quality floor without announcing it: responsive down to mobile (web), resizable terminal (TUI), visible keyboard focus, reduced motion respected.

Chanel's rule: before leaving the house, take a look in the mirror and remove one accessory.

## Writing in design

Words appear in a design for one reason: to make it easier to understand and therefore easier to use.

- Write from the end user's side. Name things by what people control, never by how the system is built.
- Active voice: "Save changes," not "Submit."
- Same name through the whole flow — the button that says "Publish" produces a toast that says "Published."
- Failure states: explain what went wrong and how to fix it. Never vague. Never apologetic.
- Empty screens: invitation to act, not a void.
- Plain verbs, sentence case, no filler, tone matched to audience.
