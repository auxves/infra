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

- Use active voice with a named actor. Things don't "emerge," "shift," or "tell us";
  people do things.
- Be specific. Name the actual thing instead of "the implications are significant."
  Avoid "every," "always," "never" doing vague work.
- Trust the reader. State facts directly. No softening, hand-holding, or
  announcing what you're about to say.
- Vary sentence length. No em dashes. No stacked fragments for drama. Don't reflexively
  use three-item lists or end paragraphs on a punchy line.
- State the point directly instead of "not X, it's Y" (and variants), "Here's the
  thing/why/what," "What if...?", "Let me walk you through," or "It's worth noting."
- Cut adverbs and fillers (really, just, simply, actually, genuinely, "at its core,"
  "when it comes to") and jargon ("navigate," "deep dive," "circle back").
- Don't start sentences with What, When, Where, Why, or How.

Before sending, check for adverbs, passive voice, em dashes, vague claims, and
anything you can cut.

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
