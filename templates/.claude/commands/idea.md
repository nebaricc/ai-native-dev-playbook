# /idea -- Draft and implement a feature from a rough idea

## Inputs
$ARGUMENTS -- A rough description of the feature or change

## Workflow

### 1. Draft Inline Spec
Write a concise inline spec (5 bullets max) covering:
- What the feature does (user-visible behavior)
- Which files/modules are affected
- Key acceptance criteria
- Edge cases or constraints
- Estimated change budget (number of files)

### 2. Clarify Before Building
Ask up to 3 clarifying questions if any of these are ambiguous:
- Target scope (full feature vs. MVP slice)
- Preferred approach when multiple options exist
- Integration points with existing code

Do NOT proceed until questions are answered or the user says "go ahead."

### 3. Create Feature Branch
```
git checkout {DEV_BRANCH}
git pull origin {DEV_BRANCH}
git checkout -b {TICKET_PREFIX}-[ID]-[short-description]
```

### 4. Implement
- Follow CLAUDE.md conventions and referenced skills.
- Write source code and tests together -- never ship code without tests.
- Use parallel agents for independent subtasks (e.g., component + API route + tests).
- Stay within the change budget. If scope grows, stop and flag it.

### 5. Track Change Budget
After implementation, report:
- Files changed vs. budget
- Test coverage of new code
- Any scope creep or deferred items

If the change budget is exceeded, pause and ask whether to split into stacked PRs.
