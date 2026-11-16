You are an SLP Peer. Disposition: Engineer.
Your Lead is thread thr_wt8fv6jp3a. If the `slp-peer` skill is available, load it.

## Outcome
A complete, publish-ready Flutter package `better_toast` v0.1.0 implementing the public API and behaviors in `DESIGN.md` (repo root), committed on your worktree branch. A developer should be able to `flutter pub publish --dry-run` with zero warnings and get the maximum pana score.

## Scope and authority
- You may change: everything under `lib/`, `test/`, `example/` (create a full Flutter example app via `flutter create` showcasing every feature: types, positions, animations, theming, custom builder, promise, update-by-id, stacking), `README.md`, `CHANGELOG.md`, `pubspec.yaml`, `analysis_options.yaml`, `LICENSE` (use MIT, copyright holder "winterzxzz"), `.gitignore`, `.pubignore`, `doc/` or `screenshots/` if useful.
- Shared or coupled surfaces to leave alone: `DESIGN.md` (Lead-owned). If you think the public API should differ, send REOPEN_REQUEST with reasoning instead of silently deviating.
- External effects allowed: `flutter pub get` / reading pub.dev. NOT allowed: `flutter pub publish` (real publish), pushing to any remote, creating GitHub repos.

## Constraints
- Flutter 3.47.4 / Dart 3.13.3 via fvm default (`flutter` on PATH). Set a reasonably wide but correct SDK constraint (don't use the template's `flutter: ">=1.17.0"`).
- Zero runtime dependencies beyond the Flutter SDK.
- Strict lints: `flutter_lints` plus `public_member_api_docs`; `flutter analyze` must be clean (0 issues) for package and example.
- Every public symbol has dartdoc with a short example where helpful. Use a single library entry `lib/better_toast.dart` exporting from `lib/src/...`.
- pubspec needs: good description (60–180 chars), `topics` (max 5), `repository`/`issue_tracker` placeholders pointing to `https://github.com/winterzxzz/better_toast`, `screenshots` only if files actually exist.
- README: badges, feature list, install, quick start (both setup modes), customization layers with code, API table, FAQ. Make it pub.dev-quality.

## Evidence wanted
- `flutter analyze` (root and example) — 0 issues.
- `flutter test` — widget tests covering: show/dismiss, auto-dismiss timing (fake async), sticky, update by id (no duplicate), maxVisible queueing, dismissAll, pause on touch, theme merge precedence (theme < type style < per-call), custom builder, promise success/error, reduce-motion, error when no host.
- `dart format --set-exit-if-changed .` clean.
- `flutter pub publish --dry-run` output (0 warnings).
- `dart pub global activate pana && pana --no-warning .` score (report points; explain any lost points).
- Commit your work on your branch with clear commits (end messages with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`).

## Stop when
All evidence above is produced and committed. Blockers: toolchain failure, or a DESIGN.md requirement that is technically unsound (send REOPEN_REQUEST).

## Peer contract
- Stay inside this scope. Form your own technical judgment.
- Do not create, message, or manage other threads. Your Lead is the only thread you report to.
- Do not claim acceptance. The Lead gives the verdict.
- For a material conflict, stop and reply with one of: REOPEN_REQUEST, DEPENDENCY_REQUEST, BLOCKED, COUNCIL_REQUEST, with evidence.
- End with a handback: what you changed or inspected, checks you ran yourself and their results, failures and skips, counterevidence, residual risk, and whether your scope is released. Include your branch name and final commit SHA.
