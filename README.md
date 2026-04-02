# PokéRogue Offline (iOS)

A WKWebView wrapper that bundles PokéRogue for fully offline play on iOS.

## How it works

- GitHub Actions clones the latest `main` branch of [pagefaultgames/pokerogue](https://github.com/pagefaultgames/pokerogue)
- Builds it with `VITE_BYPASS_LOGIN=1` (no server, local saves only)
- Bundles the output into an unsigned `.ipa`

Saves are stored in WKWebView local storage on your device and persist between sessions.

## Getting the IPA

1. Go to the **Actions** tab in this repo
2. Click the latest successful workflow run
3. Download the `PokéRogueOffline` artifact
4. Unzip it to get the `.ipa`
5. Sign and install with [Feather](https://github.com/khcrysalis/Feather) or Sideloadly

## Triggering a new build

A build runs automatically on every push to `main`. To manually trigger one:

1. Go to **Actions** tab
2. Select **Build PokéRogue Offline IPA**
3. Click **Run workflow**

## Notes

- Saves are local only — no online account sync
- Works fully in airplane mode once installed
- Landscape orientation only (matches the game's layout)
