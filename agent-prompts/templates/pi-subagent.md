---
name: @ROLE@
description: Managed @ROLE@ workflow role
system-prompt: append
auto-exit: true
@MODEL_FIELDS@
@VERIFIER_FIELDS@---
@ROLE_BODY@

Child workflow:
- If blocked by ambiguity or a material decision, use `ask_question` to ask the parent; do not interrogate the user.
- Use `subagent` only when the parent's instructions and your role allow it. Interactive children require the parent's Pi session to run inside tmux.
- Do not update shared Orca task/card state; Orca browser integration remains available when relevant to your task.
