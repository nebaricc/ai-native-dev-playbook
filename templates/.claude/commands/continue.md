# /continue -- Create a stacked PR from the current branch

Use this when the current PR is complete but related work remains that depends on it.

## Inputs
$ARGUMENTS -- Description of the next slice of work

## Workflow

### 1. Verify Current Branch
- Confirm all changes on the current branch are committed and pushed.
- Note the current branch name (this becomes the base for the stacked PR).

### 2. Create Stacked Branch
```
git checkout -b {TICKET_PREFIX}-[ID]-[next-slice-description]
```
The new branch starts from the tip of the current branch.

### 3. Reset Change Budget
Start a fresh change budget for this slice:
- Target: under 10 files changed from the parent branch.
- If the work is larger, plan to split further.

### 4. Implement
- Follow the same conventions as /idea.
- Write source code and tests together.
- Stay within the new change budget.

### 5. Push and Create Stacked PR
```
git push -u origin HEAD
```
Create PR targeting the **previous branch** (not {DEV_BRANCH}):
- Title: `type(scope): description ({TICKET_PREFIX}-ID)`
- Body: Note this is a stacked PR. Link to the parent PR.
- Include: what/why, changes, test plan.

### 6. Report
Output the chain:
```
{DEV_BRANCH} <- parent-branch (PR #N) <- this-branch (PR #M)
```
