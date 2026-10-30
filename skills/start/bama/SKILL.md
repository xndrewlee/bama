---
name: bama
description: Build any Mac or iPhone app. Start here to pick the next skill for a native macOS or iOS app.
disable-model-invocation: true
---

# Build any Mac app

Find where the user is on the path below, then call the Skill tool with the
skill for that step. One skill per call.

```text
idea -> bama-research -> bama-clone (optional) -> bama-app-brief
     -> bama-user-stories -> bama-new-mac-app
     -> bama-mac-design + bama-design-system + bama-app-icon
     -> bama-improve-loop (ux, code, design, verify, commit) -> repeat
```

An iPhone app takes the same path with `bama-new-ios-app` and
`bama-ios-duo-design`, and adds `bama-deploy-to-device` once the first
milestone builds green.

Pick the app's name first (`bama-app-brief`, step 1) and create
`<parent>/<AppName>/docs/` before research, so every skill writes into the
same folder. Design comes right after the scaffold: tokens from the first
view, and the real icon in every snapshot.

## Mac or iPhone

Check the app's folder:

```bash
"${CLAUDE_SKILL_DIR}/scripts/detect-platform.sh" <app-folder>
```

It prints `mac`, `ios`, or `unknown`, and the reason.

- `mac` or `ios`: use that column in the tables below. Do not ask.
- `unknown`: no project and no brief yet. Ask once: "Mac app or iPhone
  app?" For an iPhone app, also ask whether to optimize it for iPhone Duo
  (yes if they own one). Write the answer to `docs/BRIEF.md` as a line
  `Platform: mac`, `Platform: iphone`, or `Platform: iphone-duo`. The check
  reads it from then on.

## Plan

| The user has | Skill |
| --- | --- |
| A vague idea, or asks "what should I build" | `bama-research`, then `bama-app-brief` |
| An app they want to replace or rebuild | `bama-clone` |
| A brief or a screen index, no backlog | `bama-user-stories` |
| A spec from BAMA's `specs/` folder | `bama-app-brief` (it copies the spec) |

## Build

| The user wants to | Mac | iPhone |
| --- | --- | --- |
| Start a new project | `bama-new-mac-app` | `bama-new-ios-app` |
| Write or fix Swift and SwiftUI code | `bama-swift-swiftui` | same |
| Hook into the system: shortcuts, menu bar or widgets, share, capture | `bama-os-integrations` | `bama-ios-integrations` |
| Make it fast: hangs, stutter, GPU, video, memory | `bama-performance` | same |
| Let Claude Code, Codex, or scripts drive the app: a CLI, an MCP server | `bama-agent-cli` | none: Mac only, say so |
| Refactor, clean up, or check the code as it grows | `bama-improve-architecture` | same |

## Design

| The user wants to | Mac | iPhone |
| --- | --- | --- |
| Decide how a feature works and what it says: names, flow, modals, accessibility | `bama-ux-design` | same |
| Make it look and feel native | `bama-mac-design` | `bama-ios-duo-design` |
| An accent or brand color, a color picker, tokens | `bama-design-system` | same |
| Their own parts and feel, not Apple's: buttons, rows, sidebar, icons | `bama-design-kit` | same |
| The look of an app they name, or screenshots of one | `bama-design-from-app` | same |
| One set of colors, radii, motion, and controls for the whole app | `bama-design-system` | same |
| Fix spacing and alignment, or check the layout on the grid | `bama-layout-grid` | same |
| An app icon | `bama-app-icon` | same |

## Ship

| The user wants to | Mac | iPhone |
| --- | --- | --- |
| Build it and look at every page | `bama-build-and-verify` | `bama-build-and-verify-ios` |
| Tests, a self-test, or an agent that drives the running app | `bama-test-mac-app` | `bama-test-ios-app` |
| Put it on their own phone and keep it there | none | `bama-deploy-to-device` |
| Work through the backlog on its own | `bama-improve-loop` | same |

## Done when

You named the platform and the step, called its skill, and told the user
which skill comes after it.
