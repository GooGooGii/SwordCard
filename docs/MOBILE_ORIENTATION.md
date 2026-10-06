# Mobile landscape entry

2026-10-05, Codex. MOBILE-001.

On touch devices, starting or continuing a story tries document fullscreen followed by screen.orientation.lock('landscape'). Portrait entry shows a dedicated landscape button. Both actions originate directly in the user's click, preserving browser gesture requirements. Desktop users see no extra UI.

Fullscreen or orientation rejection is caught and gives a manual rotation prompt. Unsupported APIs also fall back to the prompt; a continue button lets the user inspect the game. Switching to landscape hides the prompt. The root is not CSS-rotated, preserving card drag coordinates, target boxes and safe-area layout.

Support is feature-detected rather than inferred from browser names. The web version cannot guarantee rotation at page load or on every browser/OS. Native Android still uses its existing landscape configuration. See [MDN orientation lock](https://developer.mozilla.org/en-US/docs/Web/API/ScreenOrientation/lock).

Validation: production build and 112 tests passed (1 skipped), plus 5 browser cases (mocked orientation success, orientation denial, fullscreen denial, absent lock API, desktop) and the existing 9-step mobile story/map/battle/reload/export/import flow. Browser errors: 0. The mock API cases verify calling order and graceful fallback; they do not certify hardware orientation lock on a physical Android/iPhone.

[Portrait captures and report](previews/mobile-orientation/validation.json), [flow report](previews/mobile-orientation/flow/validation.json). UI reviewed in actual captures. Entry mounting is isolated in src/main.tsx; helper and styles are independent of the game rules and saves.
