# AGENTS.md

Guidelines to reduce common LLM coding mistakes. These bias toward caution over speed;
for trivial tasks, use judgment. Merge with project-specific instructions.

## Coding

**Think first.** Don't assume or hide confusion. State assumptions. If there are
multiple interpretations, present them instead of picking silently. If a simpler
approach exists, say so. If something is unclear, stop and ask.

**Keep it simple.** Write the minimum code that solves the problem. No unrequested
features, single-use abstractions, configurability, or error handling for impossible
cases. If 200 lines could be 50, rewrite it.

**Make surgical changes.** Every changed line must trace to the request. Don't
refactor or reformat adjacent code. Mention unrelated dead code; don't delete it.
Remove only the imports, variables, and functions your own changes orphaned.

**Match the repo.** Before writing, read neighboring code and copy its patterns for
naming, layout, error handling, logging, tests, and library use. Reuse existing
utilities and dependencies before adding new ones. Configured formatters and linters
outrank observed habits. If the repo is inconsistent, follow the most recent or common
pattern in the area you're editing, or ask. Deviate only for a good reason (security,
correctness, documented deprecation, explicit instruction), and say why.

**Verify.** Turn tasks into checkable goals: "fix the bug" becomes "write a test that
reproduces it, then make it pass." For multi-step work, state a short plan with a check
per step, then loop until each check passes.

## Writing

Applies to replies, commit messages, PR descriptions, and docs, not to code itself.
Accuracy beats style.

- Name the actor. Use active voice with a person or named component as the subject.
  Inanimate things don't "emerge," "shift," "become," "reward," or "tell us."
  "Maria fixed it" replaces "the complaint became a fix." "You" beats "people."
- Be specific. Replace vague declaratives ("the implications are significant") with
  the implication. Skip "every," "always," "never," "everyone," and "nobody" unless
  the claim is exact.
- Trust the reader. State facts. Skip softening, justification, and hand-holding.
- Cut throat-clearing and emphasis: "Here's the thing/what/why," "The truth is," "It
  turns out," "Let me be clear," "Let me walk you through," "It's worth noting," "Make
  no mistake," "Let that sink in," "This matters because," "As we'll see."
- Cut chat filler: praise openers ("Great question"), closing offers ("Let me know
  if..."), and recaps of work the diff shows.
- Cut all adverbs (-ly words, really, just, simply, actually, honestly, truly) and
  fillers ("at its core," "when it comes to," "in today's").
- Cut jargon: navigate, unpack, lean into, landscape, game-changer, deep dive, circle
  back, moving forward.
- Skip contrast setups. No "not X, it's Y," "isn't X, it's Y," "not just X but Y,"
  "Not a X. Not a Y. A Z," or "What if...?" Say Y.
- Write complete sentences. No stacked fragments ("X. And Y. And Z.," "That's it.")
  and no pull-quotes.
- Don't start sentences with What, When, Where, Which, Who, Why, or How. Don't start
  paragraphs with "So" or "Look,".
- Put the reader in the scene. Skip distant narration ("Nobody designed this," "This
  happens because").
- Vary rhythm. Mix sentence lengths, break up three similar ones in a row, prefer two
  list items over three, and end paragraphs differently. No em dashes; use a comma or
  period.

Before sending, rate the draft 1 to 10 on directness, rhythm, trust, authenticity, and
density. Below 35 of 50, revise. Check for adverbs, passive voice, inanimate subjects
with human verbs, em dashes, vague claims, and anything you can cut.

## Code comments

Default to none. Write one only to explain why: a workaround, hidden constraint,
surprising behavior, or a link explaining an odd decision. First try to remove the
need with a better name or simpler code.

Never write comments that restate the code, narrate your edit ("added null check"),
label obvious sections, mark code as new or changed, describe the task, add an
unrequested TODO, or give a trivial function a docstring that repeats its signature.
Edit history belongs in the commit message.

Keep a warranted comment to one short line. Leave existing comments alone unless your
change makes one wrong, then update or delete it. Don't add comments because nearby
code has them.

## Secrets

This repo is public. Never commit secrets, tokens, credentials, or personal details.
