# Lessons Learned: Battle Stories from 3 Production Codebases

These are not hypothetical best practices. Every lesson here cost real time,
real compute, and in some cases real credibility. They come from applying
AI-native development across three production codebases (Signalboard, Pebble,
and Diggit) over the course of several months.

If you take one thing from this document: the hard parts of AI-assisted
development are not the AI parts. They are the same old engineering discipline
problems -- testing, branching, environment configuration, verification --
amplified by the speed at which agents operate. An agent that moves fast
without guardrails does not save you time. It creates mess at machine speed.

---

## 1. Always Git Pull Before Branching

We had a session where we spun up five agents in parallel to tackle five
independent tasks across the same repository. This is the kind of thing
that makes AI-native development exciting: five PRs created in twenty minutes,
each touching different parts of the codebase, all running concurrently.

The problem was that the local clone was 125 commits behind the dev branch.
All five agents branched from a stale state. When the PRs came in, three of
them re-implemented features that had already been merged. One of them
conflicted with a refactor that had landed two days prior. The fifth was
fine, but only by luck -- it touched a file no one else had changed.

We had to close all five PRs, pull the latest dev branch, audit what actually
still needed doing, and re-launch the agents. That is an hour of compute
time wasted, plus the human time to review, close, and re-plan. The cost
was not catastrophic, but it was entirely avoidable.

The fix is mechanical: before any branching session, run `git fetch` and
`git log --oneline dev..origin/dev` to see what you are missing. If the
answer is more than zero commits, pull first. Make this a reflex. Better
yet, make it a step in your session startup checklist. Pull, audit, branch.
Every time. No exceptions.


## 2. Rules Without Enforcement Are Suggestions

For two weeks, our CLAUDE.md file included the instruction: "All PRs must
include tests for new functionality." It was clearly written, prominently
placed, and completely ignored. Not maliciously -- agents do not rebel.
They simply optimize for the primary instruction, and if "implement feature X"
is the primary instruction, tests are a secondary concern that gets dropped
when the context window gets crowded.

During those two weeks, we merged dozens of PRs. Test coverage stayed at
zero. The CLAUDE.md instruction had the same practical effect as a "please
wash your hands" sign in a restaurant bathroom.

The fix was adding a `test-coverage-check` CI job that blocks any PR from
merging if it does not include at least one test file when source files are
modified. This is not a sophisticated coverage gate. It is a blunt instrument:
did you add a test file, yes or no? But it works. Within three days of
enabling the check, test coverage went from 0% to 80%. Agents started
writing tests because they had to, not because they were asked nicely.

The general principle here extends far beyond testing. Any rule you want
consistently followed must have automated enforcement. If the CI pipeline
does not check for it, it will not happen reliably. Instructions in
documentation are wishes. Checks in CI are requirements.


## 3. Agent Prompts Must Explicitly Say "Write Tests"

This one is related to the previous lesson but distinct enough to call out
separately. We asked an agent to "implement the notification feature." The
agent did exactly that. It read the spec, understood the requirements, wrote
clean code, handled edge cases, and created a well-structured PR. Zero tests.

This is not a bug. This is correct behavior. We said "implement," and the
agent implemented. We did not say "write tests for every new function," so
it did not write tests. Agents are literal in a way that human developers
are not. A human developer might push back and say "shouldn't we add tests?"
An agent does what you ask, precisely.

The fix is to make your prompts explicit. Not "implement X" but "implement X
with unit tests for every exported function and integration tests for the
happy path and primary error cases." Yes, this makes prompts longer. Yes,
this feels redundant if you also have a CLAUDE.md rule about tests. But
redundancy in instructions is cheap. Missing tests are expensive.

We eventually standardized on prompt templates that include the testing
requirement by default. Every task prompt ends with a section specifying
the expected test coverage. This has eliminated the "perfect implementation,
zero tests" failure mode almost entirely.


## 4. Fix Weak Tests Before Writing More

At one point we had 655 tests across the Signalboard codebase. The number
felt great. Dashboard green, test count climbing, coverage metrics looking
healthy. We were genuinely proud of the velocity.

Then someone actually read the test files.

Roughly 40% of those tests used `.toBeDefined()` as their primary assertion.
For those unfamiliar, `.toBeDefined()` passes for literally any value that
is not `undefined`. A function that should return a user object but returns
`null`? `.toBeDefined()` passes. A function that should return an array of
10 items but returns an empty array? `.toBeDefined()` passes. A function
that should return a formatted date string but returns the number 42?
`.toBeDefined()` passes.

We had hundreds of tests that could not catch regressions because they were
not actually asserting anything meaningful. The test count was a vanity
metric. It told us how many test functions existed, not how many behaviors
were verified.

The fix required an audit. We categorized every test by assertion strength:
strong (tests specific values, structures, or behaviors), medium (tests
type or shape but not exact values), and weak (`.toBeDefined()`,
`.toBeTruthy()`, or similar). The weak tests got rewritten with specific
assertions. The medium tests got reviewed case by case.

The lesson is counterintuitive: do not celebrate test count. A codebase with
100 strong tests is better protected than one with 600 weak tests. And if
you are using AI agents to generate tests, you must audit the assertions
they produce, because agents will happily generate tests that pass without
actually verifying anything useful. Fix the weak tests before writing more.


## 5. Push Context Files to Your Dev Branch

This one is embarrassing in retrospect because it is so obvious. Our CLAUDE.md
file -- the primary context document that tells agents how the project works,
what conventions to follow, and what patterns to use -- existed only on the
main branch.

Agents branch from dev.

For two weeks, every agent we launched started with zero project context.
They did not know the coding conventions. They did not know the testing
requirements. They did not know the file structure patterns. Every agent
was starting from scratch, making its own decisions about how to structure
code, where to put files, and what patterns to follow.

The result was inconsistency everywhere. One agent used default exports,
another used named exports. One put utilities in a `utils/` folder, another
put them in `lib/`. One wrote tests in `__tests__/` directories, another
co-located them with source files. Every PR required manual cleanup to
match the project's actual conventions.

The fix took thirty seconds: merge CLAUDE.md from main into dev (or better,
create it directly on dev). But the two weeks of inconsistent PRs took much
longer to clean up. The principle generalizes: any file that agents need for
context must exist on the branch those agents actually use. This includes
CLAUDE.md, .cursorrules, session files, and any other documentation that
shapes agent behavior.


## 6. Don't Demo Velocity Without Quality

This is a people lesson, not a technical one, but it matters as much as
anything in this document.

Early in the Signalboard engagement, we wanted to demonstrate the value of
AI-assisted development to the client. We ran a session and shipped four
PRs in a single afternoon. Features that would normally take a week of
developer time, done in hours. The client was impressed. The demo went well.

None of those four PRs had tests.

The client did not notice immediately. But within a week, two of those PRs
introduced bugs. Not dramatic, production-down bugs -- subtle behavioral
regressions that users reported through support channels. Suddenly, the
narrative shifted from "AI development is incredibly fast" to "AI development
shipped bugs."

The fix was test retrofits for all four PRs. The retrofits took longer than
writing the tests alongside the original code would have. And more
importantly, we had to rebuild trust. The client now (reasonably) questioned
whether our fast delivery was actually saving time or just front-loading it.

Velocity without quality is tech debt with a bow on it. When you demo
AI-assisted development, demo the whole picture: features with tests,
features with documentation, features that work correctly. Speed that
creates cleanup work is not speed. It is borrowing time from your future
self at a high interest rate.


## 7. Verify Agent Work Yourself

An agent reported: "All tests passing. PR created. 33 screenshot tests
covering every page in the application." This sounded excellent. We looked
at the PR, saw green checkmarks on CI, saw 33 test files, and merged it.

A week later, while working on a visual regression, we actually opened the
baseline screenshots. Every single one was a blank white page. All 33 of
them. The application had not rendered at all during the test runs because
the seed data was missing -- the test setup did not populate the database
that the pages needed to render content.

The tests passed because the screenshots were consistent. Every run produced
the same blank white page. The visual regression tool compared blank to
blank and found no differences. Technically, the tests were passing.
Practically, they were testing nothing.

This is a failure mode that is unique to AI-assisted development: the agent
correctly set up the test infrastructure, correctly wrote the test cases,
correctly configured the screenshot comparison -- and produced a completely
useless result. The CI was green. The agent reported success. Everything
looked fine unless you actually looked at the screenshots.

The fix was adding a verification step to our workflow: after any agent
completes visual tests, a human reviews at least a sample of the actual
output artifacts. Not the test results. The artifacts. Open the screenshots.
Read the test assertions. Check that the thing being tested is the thing
you think is being tested. Green checkmarks do not mean correct output.
They mean the assertions passed. Those are different things.


## 8. Worktree Branch Management Is Fragile

Git worktrees are a powerful tool for parallel agent development. Instead
of one agent waiting for another to finish, you can have multiple agents
working in multiple worktrees simultaneously, each on their own branch,
each touching different parts of the codebase.

The fragility is in branch management. During one session with three agents
running in three worktrees, two of the agents committed to the wrong branch.
One agent was supposed to be on `feature/notification-service` but was
actually on `feature/auth-refactor` -- a worktree that had been used in a
previous session and still had the old branch checked out. The other agent
had a similar issue but with an additional wrinkle: there was a stash from
a previous run that got silently applied, merging old changes into the new
work.

The result was two PRs with mixed changes. One PR titled "notification
service" contained auth refactor code. The other had changes from two
different features interleaved. Both had to be closed, the branches reset,
and the work redone.

Worktrees are powerful, but they require hygiene. After every agent
completes work in a worktree, verify three things: (1) the correct branch
is checked out, (2) the stash is empty, (3) `git status` shows only the
changes you expect. Better yet, create fresh worktrees for each session
rather than reusing old ones. The disk space cost of a new worktree is
trivial compared to the time cost of untangling mixed commits.


## 9. JWT Secrets and Env Var Mismatches

Visual tests worked perfectly for counselor login. The test would
authenticate as a counselor, navigate to the counselor dashboard, take a
screenshot, and compare it to the baseline. Green checkmarks every time.

Admin login tests failed. Every single one. The test would authenticate as
an admin, navigate to the admin dashboard, and get redirected to the login
page. Two hours of debugging followed.

The root cause was a one-line environment variable mismatch. The backend
signed JWTs using `JWT_SECRET` from its `.env` file. The frontend middleware
that verified JWTs on protected routes used `NEXTAUTH_SECRET` from its own
`.env` file. These were set to different values in the test environment.

Counselor routes did not verify the JWT on the frontend -- they passed the
token to the backend API, which verified it with the correct secret. Admin
routes had an additional frontend middleware check that verified the JWT
before even reaching the backend. Different verification paths, different
secrets, one worked and one did not.

The fix was literally one line: setting `NEXTAUTH_SECRET` to match
`JWT_SECRET` in the test environment configuration. But the debugging
took two hours because the failure mode was not "auth does not work" but
"auth works for some roles and not others," which sent us looking at
role-based logic, permissions tables, and middleware ordering before we
thought to check whether the basic cryptographic verification was even
using the same key.

The general principle: when something works for one case but not another,
and both cases use ostensibly the same mechanism, check whether the mechanism
actually is the same. Often there is a fork in the path that you are not
aware of, and the two branches have different configurations.


## 10. Session State Prevents Duplicate Work

AI conversations are stateless by default. Each new conversation starts
fresh. The AI does not remember what happened in the previous conversation
unless you tell it.

This caused us to redo work three times. In the first conversation, we
audited the codebase, identified priorities, and created a plan. The
conversation ended. In the next conversation, the AI did not know any of
that had happened, so we spent twenty minutes re-explaining the state of
the project. It then re-audited the codebase (arriving at slightly
different priorities because the analysis is not deterministic) and started
on a task that had already been completed in a previous conversation.

The fix was the session file pattern. We created `session-flow.md` as a
central index of what has been done and what remains, plus per-repository
`session-{repo}.md` files that track detailed status. These files live in
the repository (or in a shared context directory) and are read by the AI
at the start of every conversation.

The effect was immediate. The next conversation after implementing session
files, the AI read `session-flow.md`, understood exactly what had been
completed, and picked up precisely where we left off. No re-auditing,
no duplicate work, no conflicting priorities.

An unexpected benefit: the session files helped the human side too. Across
three repositories with dozens of tasks each, it became genuinely difficult
to remember what state each project was in. The session files served as a
shared memory between human and AI, and between the human's past self and
present self. They are now a non-negotiable part of our workflow.

The format matters less than the discipline. Whether you use markdown
checklists, YAML status files, or a database, the key is that the state
is written down, machine-readable, and updated after every milestone. The
AI should both read and write to the session state. If only the human
updates it, it will fall out of date. If only the AI updates it, the human
will not trust it.


---


## General Principles

The ten lessons above cover specific incidents, but they cluster around a
smaller set of underlying principles. If you internalize these, you will
avoid not just the specific mistakes we made, but the entire class of
mistakes they represent.


### Trust but Verify

AI agents are competent. They write good code, structure projects well,
and handle complex tasks with minimal guidance. But they are not infallible,
and their failure modes are different from human failure modes. A human
developer who ships broken code usually knows it is risky. An agent that
ships broken code reports success with full confidence.

This means verification is not optional. Not "verify when you are suspicious"
but "verify always." Look at the actual output, not just the status report.
Open the screenshots, read the test assertions, check the branch name,
review the diff. The verification step takes minutes. The cleanup from
unverified work takes hours.

This does not mean you should distrust agents or micromanage every step.
The point of AI-assisted development is that agents handle the bulk of the
work. But the human's role shifts from "write the code" to "verify the
output and direct the next step." That role is essential and cannot be
automated away.


### Enforcement over Instructions

If you want something to happen consistently, enforce it mechanically.
CI checks, pre-commit hooks, linting rules, automated gates -- these are
your actual requirements. Everything else is a suggestion.

This applies to test coverage, code style, branch naming, commit message
format, PR structure, and any other standard you care about. If it is not
checked by automation, it will drift. Not because agents are defiant, but
because instructions compete for attention in a context window, and the
primary task always wins.

Write the rule in CLAUDE.md for context. Enforce the rule in CI for
compliance. Both are necessary. Neither is sufficient alone.


### Explicit over Implicit

Agents do not infer intent the way experienced human collaborators do. A
senior developer who hears "implement the notification feature" will
probably write tests, update documentation, and handle error cases without
being asked. An agent will implement the notification feature. Exactly
that, and nothing more.

This is not a limitation to work around. It is a characteristic to design
for. Make your prompts explicit about every expectation: tests, error
handling, documentation, edge cases, performance considerations, security
requirements. If you do not mention it, assume it will not happen.

Over time, you build prompt templates that encode these expectations by
default. The templates are verbose, but verbosity in instructions is cheap.
Missing requirements are expensive.


### Small over Large

Small, focused tasks produce better results than large, ambiguous ones.
An agent asked to "refactor the authentication system" will produce
unpredictable results. An agent asked to "extract the JWT validation logic
from `auth.ts` into a separate `validateToken` function with tests" will
produce exactly what you need.

This principle applies to PRs as well. Five small PRs that each do one
thing are easier to review, easier to test, and easier to revert than one
large PR that does five things. When an agent produces a large PR, it is
usually a sign that the task was too broadly scoped.

The overhead of managing more tasks is real, but it is dramatically lower
than the overhead of debugging a large, tangled changeset. Break work into
the smallest units that make sense, and let the agents run them in parallel.


### Parallel over Sequential

The single biggest leverage point in AI-native development is parallelism.
Agents do not get tired, do not context-switch, and do not need to wait
for inspiration. If you have five independent tasks, launch five agents.
If you have ten independent tasks, launch ten agents. The marginal cost of
an additional parallel agent is near zero; the time savings are linear.

But parallelism requires independence. Tasks that modify the same files
cannot run in parallel without merge conflicts. Tasks that depend on each
other's output must run sequentially. The skill is in decomposing work into
independent units that can run concurrently.

This is where planning pays off. Spending ten minutes identifying which
tasks are truly independent -- which files they touch, which APIs they
depend on, which state they modify -- saves hours of conflict resolution.
Plan the parallelism. Do not hope for it.

Parallel execution also amplifies every other lesson in this document. If
you do not pull before branching, you waste five agents instead of one. If
you do not verify output, you merge five bad PRs instead of one. If your
prompts are not explicit, you get five inconsistent implementations instead
of one. The speed multiplier works in both directions.


---

## 11. Multi-Repo Session Scope Bites You Silently

When working across multiple repos in one Claude Code session, agents will silently fail to write files if they're outside the session's working directory. The agent reports success, the file never appears.

**Root cause**: Claude Code scopes file and bash permissions to the directory it was launched from. A session launched from `~/dev/pebble` cannot write to `~/dev/signalboard`.

**Fix**: Launch from the common parent directory (`cd ~/dev && claude`), or use separate Claude Code sessions — one per repo. When using parallel agents on cross-repo work, verify each agent's target path is within scope before launching.

**How to detect it**: If an agent says it wrote files but they don't appear, check whether the target path is inside the session's working directory.

---

## 12. Skills Beat Rules When It Comes to Security and Compliance

Putting security requirements in CLAUDE.md as bullet points does not work. The agent reads them once and proceeds. By the time it's writing a new endpoint, the security rules are out of context.

What works: dedicated `security/` and `compliance/` skill files, explicitly mandated in CLAUDE.md with "load this before every feature." The skill file is loaded fresh when it's relevant. The mandate in CLAUDE.md makes loading it non-optional.

Even better: break compliance into sub-skills (`compliance/ferpa.md`, `compliance/coppa.md`) so only the relevant piece is loaded. A K-12 platform building a student feature loads FERPA rules. Building a payment feature loads PCI rules. The agent gets targeted context, not an overwhelming dump of every regulation.

The pattern: CLAUDE.md says *what* to load and *when*. The skill file contains *how* to comply.

---

## 13. GitHub Secrets Belong at the Environment Level, Not the Repo Level

Early in one engagement, we stored all CI/CD credentials as repo-level GitHub
secrets with environment prefixes: `PROD_WIF_PROVIDER`, `STAGE_WIF_PROVIDER`,
`PROD_DATABASE_URL`, and so on. The naming convention felt organized. It was not
secure.

Repo-level secrets are accessible to any workflow in the repository, on any
branch. A workflow on a feature branch, a dependency update PR, or a third-party
GitHub Action could all read `PROD_WIF_PROVIDER`. The prefix in the name does not
create any access boundary — it is just a label.

GitHub Environments (Settings → Environments → `production`, `staging`,
`development`) solve this properly. Secrets stored at the environment level are
only available to workflow jobs that explicitly declare `environment: production`.
Combined with environment protection rules (required reviewers, deployment branch
restrictions), this means prod credentials are gated by both the code and GitHub's
access control layer.

The fix is structural:
- Create GitHub environments for each deployment target
- Move secrets from repo-level to the appropriate environment
- Drop the prefix from secret names — `WIF_PROVIDER` resolves to the right value
  per environment automatically
- Remove the old repo-level secrets once environments are set up

The tell that you have this wrong: secret names with environment prefixes
(`PROD_*`, `STAGE_*`). The prefix is a sign the secret is at the wrong scope.


## 14. Public Config Does Not Belong in Secrets

Firebase web SDK configuration — `apiKey`, `authDomain`, `projectId`, `appId` —
is public by design. Firebase's security model explicitly states that these
values are safe to commit and expose to browsers. The `NEXT_PUBLIC_` prefix in
Next.js exists precisely for this pattern: values that are intentionally
client-side.

We had all of these in GitHub secrets. `NEXT_PUBLIC_FIREBASE_API_KEY`,
`STAGE_FIREBASE_API_KEY`, `PROD_FIREBASE_API_KEY`, and so on. Eighteen secrets
that needed to be rotated, audited, and kept in sync, for values that are safe
to put in a committed `.env.dev` file.

The fix: committed per-environment config files (`.env.dev`, `.env.stage`,
`.env.prod`) contain public Firebase config. CI workflows copy the right file
for the environment during build. No secrets needed. The values are visible in
the repository, which is correct — they are not secrets.

Before storing something in GitHub secrets, ask: what is the actual harm if
this value is read by someone who shouldn't have it? If the answer is "none"
— because it's already in your client-side bundle, or because it's a project
identifier, not an authorization credential — it does not belong in secrets.
Secrets are for things that authorize access. Config is for things that
identify services.


## 15. Firebase Admin SDK on the Backend Is Often Unnecessary

Firebase Admin SDK is the standard recommendation for verifying Firebase Auth
tokens on the backend. The documentation says to use it. Most tutorials use it.
We used it for months.

Then we asked: what does it actually do? It verifies JWTs. Firebase ID tokens
are standard JWTs signed by Google's Secure Token Service. The signing keys are
published at a public JWKS endpoint. Any JWT library can verify them without
the Admin SDK.

```typescript
// jose is already in most backends. No firebase-admin needed.
const FIREBASE_JWKS = createRemoteJWKSet(
  new URL('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com')
);

const { payload } = await jwtVerify(idToken, FIREBASE_JWKS, {
  issuer: `https://securetoken.google.com/${projectId}`,
  audience: projectId,
});
```

Removing `firebase-admin` from the backend eliminates a large transitive
dependency tree (gRPC, protobuf, and more), removes the requirement for ADC
or service account credentials at runtime, and simplifies testing — no more
mocking the entire Admin SDK module.

The other thing `firebase-admin` was doing for us: setting custom claims
(role, school ID) on Firebase users. Replacing this with a database lookup
on session creation is more correct — roles should live in your database, not
in your identity provider. Firebase is the authentication layer. Authorization
data belongs where you own it.

The broader lesson: when a framework SDK does two things and you only need one
of them, check if the one you need can be done without the SDK. Large SDKs
carry hidden costs in dependency surface, credential requirements, and test
complexity. JWT verification is a solved problem. You do not need a Firebase
package to verify a Firebase token.

---

These lessons will continue to evolve. AI-native development is not a
solved problem; it is a practice that improves through iteration. The
playbook, the tooling, and the habits all get better as you learn what
works and what does not. The key is to learn from each incident, encode
the lesson in automation where possible, and share the story so others
do not have to learn it the hard way.
