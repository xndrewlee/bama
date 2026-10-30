# When the data lives on a server

The template keeps its data on the phone in SwiftData. Some apps are a
second client for a server the user already runs: a dashboard on a Mac
mini, reached over Tailscale. The data stays there; the phone keeps only
its settings.

## Shape

- `Kit/` holds a `Dashboard` protocol (what the app asks the server), the
  real client over `URLSession`, the API types, and a `FixtureDashboard`
  with made-up answers. All Foundation, so `make test` covers them on the
  Mac.
- The app picks the client at launch: the real one, or the fixtures in a
  test run. Views take `any Dashboard` from the app model, never a
  `URLSession`.
- Delete `Item`, `Store`, `SeedData.swift`, and `.modelContainer` from the
  template. Keep `APP_STORE`: the tools set it for every snapshot,
  self-test, and UI test, so it still marks a test run. Rename `Store` to
  `TestRun` with one `isActive` check.
- A test run keeps its settings in their own `UserDefaults` suite, cleared
  at launch, so tests never change the person's settings.

## Fixtures

- Never snapshot or test against the real server: its content changes,
  and it may be private or for adults. Snapshots refuse to run outside a
  test run.
- Made-up names and text, in the app's language. Images are drawn, not
  fetched: an image URL of `fixture:<n>` draws a gradient and a symbol.
- One clock for every fixture (`static let started = Date.now`): a fixture
  made twice must compare equal, or a self-test check flakes on the second
  boundary.
- `FixtureDashboard` has modes (`normal`, `unreachable`, `wrongServer`) and
  records the queries it got, so the self-test and the snapshots show
  every state.

## Reaching the server

- Prefer HTTPS from `tailscale serve` on the server's Mac
  (`https://<mac>.<tailnet>.ts.net`): it needs no App Transport Security
  exception. Plain HTTP to a tailnet address needs one.
- The simulator reaches the tailnet when this Mac is on it. A real phone
  needs Tailscale on and the server allowed in the tailnet's rules.
- A settings page holds the address, with the server's real address as the
  default. Check a new address (a health endpoint that names the service)
  before saving it; a bad one keeps the old one and says why.
- The main page has an unreachable state: what failed, "check that
  Tailscale is on", Try Again, and a link to the address setting.
- Ask before changing anything on the server's Mac. Read its code over SSH;
  a key with a passphrase needs `ssh-add --apple-use-keychain` once, typed
  by the user.

## Gotchas from a real app

- Read the server's times with its time zone. One server sent local
  times with no zone; read as the phone's time, every start was in the
  future.
- Decode remote images at the size they are shown (`CGImageSourceCreateThumbnailAtIndex`)
  and cache them. One avatar measured 2217 x 2217 and 2.8 MB, for a 40 pt circle.
- A signed media URL keeps its query exactly as the server encoded it.
  Decoding and encoding it again breaks the signature.
- Measure what the phone gets from the server before picking a default
  quality: over the house Wi-Fi it was about 4 Mbps, Tailscale or not. Video
  that streams needs an adaptive playlist
  (`bama-ios-integrations`, recipes.md, "Video and Picture in Picture").
- The simulator and the Mac share the Mac's network. Check playback,
  chat, and speed on the phone, against the real server.
- `URLSession.bytes(for:).lines` drops blank lines, which normally end a
  server-sent event. It works when the server sends one `data:` line per
  event; say so in the parser.
- A self-test that counts requests races with the page on screen, which
  loads too when the shared model changes. Count on a model and fixture of
  its own.
