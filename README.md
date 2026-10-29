<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/banner-dark.png">
  <source media="(prefers-color-scheme: light)" srcset="docs/assets/banner-light.png">
  <img alt="BAMA: Build Any Mac App" src="docs/assets/banner-light.png" width="860">
</picture>

### See an app you like. Rebuild it as your own native Mac app.

Agent skills that take a native macOS app from idea to your Dock.<br>
Swift and SwiftUI. Local data. No Xcode GUI.

[![macOS 26+](https://img.shields.io/badge/macOS-26%2B-000000?style=flat-square&logo=apple&logoColor=white)](#requirements)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-F05138?style=flat-square&logo=swift&logoColor=white)](#requirements)
[![22 skills](https://img.shields.io/badge/skills-22-5E5CE6?style=flat-square)](#skills)
[![Claude Code plugin](https://img.shields.io/badge/Claude_Code-plugin-D97757?style=flat-square&logo=claude&logoColor=white)](#install)
[![Codex plugin](https://img.shields.io/badge/Codex-plugin-10A37F?style=flat-square)](#install)
[![MIT license](https://img.shields.io/badge/license-MIT-F4C430?style=flat-square)](LICENSE)

**[Quick start](#quick-start) · [Fork changes](#changes-in-this-fork) · [How it works](#how-it-works) · [Skills](#skills) · [Specs](#specs) · [Install](#install)**

</div>

## Changes in this fork

This is a fork of [daveebbelaar/bama](https://github.com/daveebbelaar/bama). It changes four things:

- **Every skill is named `bama-<name>`.** Upstream's generic names, like `research`, `clone`, and `performance`, clashed with other skill packs. The router is still `/bama`. The naming scheme comes from the [hmaddocks/bama](https://github.com/hmaddocks/bama) fork by hmaddocks.
- **The link script keeps other skills safe.** `scripts/link-skills.sh` replaces only links that point into your clone. If another skill or folder has the same name, the script leaves it alone, names it, and exits with an error. It also removes links into your clone whose skill is gone, such as the old names without the prefix.
- **Installs come from this fork.** The install commands below and `plugin.json` point at `xndrewlee/bama`.
- **iPhone and iPhone Duo support is in progress.** The plan is in [docs/ios-duo-support.md](docs/ios-duo-support.md). So far `/bama` tells Mac and iPhone projects apart, and `bama-new-ios-app` scaffolds an iPhone app that runs on the iPhone Duo simulator. The Mac path works as before.

## Quick start

```bash
npx skills@latest add xndrewlee/bama
```

Then ask your agent:

```text
Clone my to-do app as a native Mac app.
Screenshot every screen, write the user stories, and build milestone 1.
```

Not sure where to start? Type `/bama`. It looks at your project and picks the next skill.

## How it works

<table>
<tr>
<td width="33%" valign="top">

**1. Clone**

Your agent opens the app you like and screenshots every screen. It writes a screen index.

</td>
<td width="33%" valign="top">

**2. Plan**

It turns the screens into user stories with checkable acceptance criteria, in milestones.

</td>
<td width="33%" valign="top">

**3. Build**

It builds one story per commit. Before each commit it snapshots every page in light and dark mode and runs the tests.

</td>
</tr>
</table>

## Skills

Every skill is named `bama-<name>`, so it sits next to other skill packs without a clash. The router is plain `/bama`.

<table>
<tr><th>Stage</th><th>Skill</th><th>What it does</th></tr>
<tr><td rowspan="4" valign="top"><b>Start</b></td><td nowrap><a href="skills/start/bama/SKILL.md"><samp>bama</samp></a></td><td>Router: finds where you are and calls the right skill</td></tr>
<tr><td nowrap><a href="skills/start/bama-app-brief/SKILL.md"><samp>bama-app-brief</samp></a></td><td>Turns an idea into a one-page brief</td></tr>
<tr><td nowrap><a href="skills/start/bama-new-mac-app/SKILL.md"><samp>bama-new-mac-app</samp></a></td><td>A working app from a template: Swift package, SwiftData, build script, snapshot mode, git</td></tr>
<tr><td nowrap><a href="skills/start/bama-new-ios-app/SKILL.md"><samp>bama-new-ios-app</samp></a></td><td>A working iPhone app, ready for iPhone Duo: XcodeGen project, SwiftData, Makefile, snapshot mode on the simulator, git</td></tr>
<tr><td rowspan="3" valign="top"><b>Plan</b></td><td nowrap><a href="skills/plan/bama-research/SKILL.md"><samp>bama-research</samp></a></td><td>Parallel researcher agents: market, users, features, design, macOS APIs</td></tr>
<tr><td nowrap><a href="skills/plan/bama-clone/SKILL.md"><samp>bama-clone</samp></a></td><td>Screenshots every screen of any app with computer use or a browser, writes a screen index</td></tr>
<tr><td nowrap><a href="skills/plan/bama-user-stories/SKILL.md"><samp>bama-user-stories</samp></a></td><td>A backlog with checkable acceptance criteria, in milestones</td></tr>
<tr><td rowspan="5" valign="top"><b>Code</b></td><td nowrap><a href="skills/code/bama-swift-swiftui/SKILL.md"><samp>bama-swift-swiftui</samp></a></td><td>Swift 6 concurrency, state, SwiftData, AppKit bridges, compiler errors</td></tr>
<tr><td nowrap><a href="skills/code/bama-os-integrations/SKILL.md"><samp>bama-os-integrations</samp></a></td><td>Global hotkeys, menu bar, floating panels, window control, screen capture, Shortcuts, URL schemes, CLI, permissions</td></tr>
<tr><td nowrap><a href="skills/code/bama-performance/SKILL.md"><samp>bama-performance</samp></a></td><td>Measure, then fix: main thread, GPU compositing, images, Instruments from the command line</td></tr>
<tr><td nowrap><a href="skills/code/bama-improve-architecture/SKILL.md"><samp>bama-improve-architecture</samp></a></td><td>Finds hot spots as the app grows and refactors one step per commit, with behavior proven unchanged</td></tr>
<tr><td nowrap><a href="skills/code/bama-agent-cli/SKILL.md"><samp>bama-agent-cli</samp></a></td><td>Optional: a command line and MCP server, so Claude Code, Codex, and scripts can drive your app</td></tr>
<tr><td rowspan="7" valign="top"><b>Design</b></td><td nowrap><a href="skills/design/bama-ux-design/SKILL.md"><samp>bama-ux-design</samp></a></td><td>Names, flow, where each feature opens (inline, popover, sheet, window), words, and accessibility, before code</td></tr>
<tr><td nowrap><a href="skills/design/bama-mac-design/SKILL.md"><samp>bama-mac-design</samp></a></td><td>Liquid Glass, layout, toolbars, menus, keyboard, type, dark mode</td></tr>
<tr><td nowrap><a href="skills/design/bama-design-system/SKILL.md"><samp>bama-design-system</samp></a></td><td>Native look with an accent color people pick in Settings, then one set of tokens and one rules page</td></tr>
<tr><td nowrap><a href="skills/design/bama-layout-grid/SKILL.md"><samp>bama-layout-grid</samp></a></td><td>A 4 pt grid with checks that fail on misalignment: a code lint, a layout probe in snapshot mode, and a grid overlay</td></tr>
<tr><td nowrap><a href="skills/design/bama-design-kit/SKILL.md"><samp>bama-design-kit</samp></a></td><td>Your own parts, not Apple's: three token layers, type, an icon set, every part in every state, custom window chrome, and a parts gallery</td></tr>
<tr><td nowrap><a href="skills/design/bama-design-from-app/SKILL.md"><samp>bama-design-from-app</samp></a></td><td>Rebuilds the look of an app you like from its screenshots: measures sizes, type, and colors, then compares pixel by pixel until it matches</td></tr>
<tr><td nowrap><a href="skills/design/bama-app-icon/SKILL.md"><samp>bama-app-icon</samp></a></td><td>A Liquid Glass icon written as an Icon Composer file, checked in every look</td></tr>
<tr><td rowspan="3" valign="top"><b>Ship</b></td><td nowrap><a href="skills/ship/bama-build-and-verify/SKILL.md"><samp>bama-build-and-verify</samp></a></td><td>Build, install, snapshot every page in light and dark, look at them</td></tr>
<tr><td nowrap><a href="skills/ship/bama-test-mac-app/SKILL.md"><samp>bama-test-mac-app</samp></a></td><td>Swift Testing, an in-app self-test, a debug bridge an agent can drive</td></tr>
<tr><td nowrap><a href="skills/ship/bama-improve-loop/SKILL.md"><samp>bama-improve-loop</samp></a></td><td>Works through the backlog one story per commit until a milestone is done</td></tr>
</table>

## Specs

Not sure what to build? [specs/](specs/) has 12 build plans for small Mac apps: a window snapper, a window switcher, a launcher, clipboard history, screenshots, a screen recorder, and more. I took them apart from Onyx, my own menu bar app. Copy one into an empty folder and tell your agent:

```text
Build the app in window-snapper.md with BAMA.
```

## Install

Pick one route per agent. Two routes install every skill twice.

<details open>
<summary><b>Claude Code</b></summary>

```text
/plugin marketplace add xndrewlee/bama
/plugin install bama@bama
```

</details>

<details>
<summary><b>Codex</b></summary>

```bash
codex plugin marketplace add xndrewlee/bama
codex plugin add bama@bama
```

</details>

<details>
<summary><b>Any other agent</b> (Cursor, Gemini CLI, Copilot, and more)</summary>

Uses [skills.sh](https://skills.sh). Install all skills, or one with `--skill`.

```bash
npx skills@latest add xndrewlee/bama -a <agent>
npx skills@latest add xndrewlee/bama --skill=bama-clone
```

</details>

<details>
<summary><b>By hand</b></summary>

```bash
git clone https://github.com/xndrewlee/bama.git
bama/scripts/link-skills.sh       # links every skill into ~/.claude/skills and ~/.agents/skills
```

The script replaces only links that point into your clone. If another skill or folder already has the same name, it leaves it alone, names it, and exits with an error.

</details>

## Requirements

- macOS 26 or later
- Xcode 26 or later, for the Swift 6.2 toolchain (you never open it)
- An agent that supports skills: Claude Code, Codex, Cursor, Gemini CLI
- For `bama-clone` on native apps: computer use (Claude Pro or Max)

## Credits

- The idea and the "any" promise come from
  [REA: Reverse Engineer Anything](https://github.com/morluto/rea) by morluto.
  REA showed that an agent can reverse engineer any app. BAMA takes that idea to the Mac.
- The `bama-` prefix and the link script that keeps other skills safe come from
  the [hmaddocks/bama](https://github.com/hmaddocks/bama) fork by hmaddocks.
- Skill format and writing rules follow Matt Pocock's
  [skills](https://github.com/mattpocock/skills) and his
  `writing-for-agents` skill.
- Works well with [SwiftUI Pro](https://github.com/twostraws/SwiftUI-Agent-Skill)
  by Paul Hudson and [SwiftUI Expert](https://github.com/AvdLee/SwiftUI-Agent-Skill)
  by Antoine van der Lee.

## License

[MIT](LICENSE)
