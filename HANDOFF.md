# better_toast — SLP handoff packet (2026-11-17)

Written by the SLP Lead (thread `thr_wt8fv6jp3a`) to continue next session.
Excluded from the pub.dev archive by `.pubignore` once the candidate lands.

## Objective
Publish a highly customizable, dependency-free Flutter toast package
`better_toast` v0.1.0 on pub.dev at max pana score, aligned with the Human's
other packages (flutter_debug_tracker, photo_library_kit, liquid_glass_native).
The Human runs the real `flutter pub publish` personally.

## Current state
| Item | State |
|---|---|
| `main` | `150972b` scaffold + `DESIGN.md` (API contract) + this file |
| Candidate | branch `bb/peer-engineer-implement-better-toast-v0-1-0-thr_9pgk5a8bgz` @ `6eccfa0` (6 commits). NOT merged: no verdict yet |
| Remote | `github.com/winterzxzz/better_toast` — created **private**; both branches pushed. Must be made public before publishing (pubspec/README link to it): `gh repo edit winterzxzz/better_toast --visibility public --accept-visibility-change-consequences` |
| Engineer `thr_9pgk5a8bgz` | Done, scope released. Worktree `~/.bb/plugins/environment-git-worktree/host-data/worktrees/thr_9pgk5a8bgz-1/better_toast` (env `env_pwwqkt6snx`) |
| Reviewer `thr_x28ahs9c7i` | Was still running at handoff (read-only, on the Engineer worktree). Read its result: `bb thread output thr_x28ahs9c7i` |
| Beads Central | Unavailable (`CONNECTION_CLOSED`); issue state `UNKNOWN`. Human has not chosen A (continue, backfill issues) / B (pause). Lead proceeded under A |

## Evidence (Lead re-ran on 6eccfa0)
`dart format` clean · `flutter analyze` 0 issues (package + example) ·
`flutter test` 61/61 · `pub publish --dry-run` 0 warnings.
pana 160/160 is Engineer-reported only (not re-run by Lead).

## Accepted decisions
- Public API per `DESIGN.md`, plus Engineer additions accepted: per-call
  `duration: null` = use theme, `Duration.zero` = sticky; `show(String? text,
  {Widget? message})`; RTL positions topStart/topEnd/bottomStart/bottomEnd;
  `handle.pause()/resume()/progress`; `BetterToast.isActive(id)`;
  `maxVisible` counted per host across positions.
- Conventions (Lead ruling 1): MIT "Copyright (c) 2026 winterzxzz", 5 topics,
  `.pubignore` mirrors `.gitignore` + excludes WORKSPACE_PROTOCOL.md /
  paseo.json / AGENTS.md / CLAUDE.md / DESIGN.md, SEO README like
  photo_library_kit, Conventional Commits.
- `HANDOFF.md` must also be excluded in `.pubignore` when merging (add it).

## Open risks
- SDK lower bound `>=3.27.0` declared but only tested on Flutter 3.47.4.
- Example never run on a real device/desktop.
- README images use raw.githubusercontent `main` URLs: broken until the
  candidate is merged to `main` and the repo is public.
- Engineer added `flutter_tester` to the shared Flutter 3.47.4 cache
  (official binary, matching engine) and installed `pana` globally.

## Resume from here
1. `bb thread output thr_x28ahs9c7i` → read Reviewer findings. (If the
   thread was stopped before finishing, re-spawn a Reviewer with
   `doc/slp/reviewer.md` on env `env_pwwqkt6snx`.)
2. Blockers/should-fix → send to an Engineer (resume `thr_9pgk5a8bgz` or a
   new Engineer in its worktree), then re-verify.
3. Lead re-runs checks + pana, merges branch into `main`, adds `HANDOFF.md`
   to `.pubignore`, pushes, gives verdict to Human.
4. Human: make repo public, `git tag v0.1.0`, `flutter pub publish`.
5. Archive Peers after verdict (`bb thread archive <id>`; integrate first).
