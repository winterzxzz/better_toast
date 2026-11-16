LEAD RULING 1 — align with the Human's existing published packages (flutter_debug_tracker, liquid_glass_native, photo_library_kit in /Users/winterzxzz/Documents/Local/AppMobiles). You may read those repos for reference (read-only). These conventions are binding, they refine your assignment:

1. pubspec: `repository: https://github.com/winterzxzz/better_toast`, `issue_tracker: .../issues`, exactly 5 `topics`, description 60–180 chars, keyword-rich (toast, notification, snackbar alternative, customizable, no context). Add `screenshots:` entries ONLY for files that really exist — produce real screenshots/GIF of the example into `doc/screenshots/` (png/webp/gif) if you can render them (e.g. golden/`flutter test` screenshot capture or macOS desktop run); if you cannot produce real images, omit `screenshots:` and say so in the handback. Never reference missing files.
2. LICENSE: MIT, `Copyright (c) 2026 winterzxzz`.
3. analysis_options: `include: package:flutter_lints/flutter.yaml`, exclude build/**, plus rules prefer_const_constructors, prefer_final_locals, always_declare_return_types, public_member_api_docs.
4. CHANGELOG: `## 0.1.0` header then `* ` bullets of features ("Initial release." line first).
5. .pubignore: it REPLACES .gitignore for pub, so mirror the .gitignore rules (see photo_view_custom_flutter/.pubignore), and also exclude `WORKSPACE_PROTOCOL.md`, `paseo.json`, `AGENTS.md`, `CLAUDE.md`, `DESIGN.md`, `example/build/`.
6. README structure (SEO-style, like photo_library_kit/README.md): H1 `# better_toast: <keyword-rich tagline>`, badges row (pub version, pub points, likes, license MIT, platforms), banner image only if it exists (use raw.githubusercontent.com/winterzxzz/better_toast/main/... URLs for images), then `## Contents`, Features, Screenshots, Installation, Quick start, customization sections, Example app, Platform support table, FAQ, Contributing, License.
7. Commits: Conventional Commits (`feat:`, `docs:`, `chore:`, `test:`), each ending with the Co-Authored-By line.

No reply needed; include compliance with each point in your handback.
