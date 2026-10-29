---
name: bama
description: Build any Mac app. Start here to pick the next skill for a native macOS app.
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

Pick the app's name first (`bama-app-brief`, step 1) and create
`<parent>/<AppName>/docs/` before research, so every skill writes into the
same folder. Design comes right after the scaffold: tokens from the first
view, and the real icon in every snapshot.

## Plan

| The user has | Skill |
| --- | --- |
| A vague idea, or asks "what should I build" | `bama-research`, then `bama-app-brief` |
| An app they want to replace or rebuild | `bama-clone` |
| A brief or a screen index, no backlog | `bama-user-stories` |
| A spec from BAMA's `specs/` folder | `bama-app-brief` (it copies the spec) |

## Build

| The user wants to | Skill |
| --- | --- |
| Start a new project | `bama-new-mac-app` |
| Write or fix Swift and SwiftUI code | `bama-swift-swiftui` |
| Hook into macOS: hotkeys, menu bar, windows, screen capture, Shortcuts | `bama-os-integrations` |
| Make it fast: hangs, stutter, GPU, video, memory | `bama-performance` |
| Let Claude Code, Codex, or scripts drive the app: a CLI, an MCP server | `bama-agent-cli` |
| Refactor, clean up, or check the code as it grows | `bama-improve-architecture` |

## Design

| The user wants to | Skill |
| --- | --- |
| Decide how a feature works and what it says: names, flow, modals, accessibility | `bama-ux-design` |
| Make it look and feel like a Mac app | `bama-mac-design` |
| An accent or brand color, a color picker, tokens | `bama-design-system` |
| Their own parts and feel, not Apple's: buttons, rows, sidebar, icons | `bama-design-kit` |
| The look of an app they name, or screenshots of one | `bama-design-from-app` |
| One set of colors, radii, motion, and controls for the whole app | `bama-design-system` |
| Fix spacing and alignment, or check the layout on the grid | `bama-layout-grid` |
| An app icon | `bama-app-icon` |

## Ship

| The user wants to | Skill |
| --- | --- |
| Build it and look at every page | `bama-build-and-verify` |
| Tests, a self-test, or an agent that drives the running app | `bama-test-mac-app` |
| Work through the backlog on its own | `bama-improve-loop` |

## Done when

You named the step, called its skill, and told the user which skill comes
after it.
