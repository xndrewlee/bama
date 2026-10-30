# Duo reading list

A reading list for iPhone Duo: the books you read, your notes on each, and
a reading timer. It uses every pose, so it doubles as the end-to-end test
for BAMA's iPhone skills. Replaces: a notes file of books, Goodreads for
one person. Written for this fork, not taken from Onyx.

## Brief

```markdown
# Shelf

Platform: iphone-duo

A reading list for one person: what I'm reading, what's next, what I thought, and how long I read today.

## Replaces
A notes file of book titles, and Goodreads used only as a private list.

## Main jobs
1. Add a book and move it from To Read to Reading to Finished.
2. Write notes and quotes for a book while I read it.
3. Time a reading session and log the pages I read.

## Data
- Book: title, author, status (toRead, reading, finished), totalPages, currentPage, addedAt, finishedAt, uuid
- Note: text, isQuote, page, createdAt, book (Book)
- Session: startedAt, minutes, pagesRead, book (Book)

## Shape
List and detail: a sidebar with Reading, To Read, and Finished, a list of books, and a book page.
Open like a book, the book page spreads over two facing pages. Half folded on a table, the reading timer
shows on the top half and its controls on the bottom half.
iOS 27.0 or later, made for iPhone Duo. Local data. Works offline. No accounts.

## System hooks
Share a quote (ShareLink). None in version one beyond that.

## Reference
none

## Look
Native, with a warm accent (orange). System fonts; quotes in the serif design.

## Not in version one
- A Home Screen widget with reading progress: it needs an App Group, so a paid Apple ID
- Book covers and search from an online catalog
- Sync between devices
- Reading goals and streaks
```

## How it works

| Part | API | Free Apple ID |
| --- | --- | --- |
| Library and book page | `NavigationSplitView` with `columnVisibility` at `.doubleColumn`, the list on the fold (`UI/Fold.swift` in the template) | Yes |
| Two facing pages | The "Two pages" pattern: split on the `.division` reserved region, half the width without one | Yes |
| Tabletop timer | A horizontal `.division` region: the timer above it, controls below it | Yes |
| Reading timer | `TimelineView(.periodic(from:by:))`, `.sensoryFeedback` on start and stop | Yes |
| Data | SwiftData: `Book`, `Note`, `Session` | Yes |
| Share a quote | `ShareLink` | Yes |
| On the phone | `bama-deploy-to-device`, renewed every week by its agent | Yes |

Patterns and code: [bama-ios-duo-design](../skills/design/bama-ios-duo-design/SKILL.md),
[patterns.md](../skills/design/bama-ios-duo-design/patterns.md) ("List-detail split on the fold",
"Two pages"). Checks: [bama-build-and-verify-ios](../skills/ship/bama-build-and-verify-ios/SKILL.md).

Types to create:

- `Book`, `Note`, `Session` (`@Model`), replacing the template's `Item`. `Book.status` is a `String`-backed enum, so `#Predicate` can filter it.
- `ShelfKit` (the template's `Kit` package): `ReadingMath` (pages left, percent read, minutes per page) and `BookTitle.clean`, with Swift Testing tables.
- `SidebarItem`: `reading`, `toRead`, `finished`. Snapshot mode walks every case.
- `BookList`, `BookPage` (the two-page spread), `NotesList`, `SessionTimer`, `TabletopLayout`.

Exact behavior:

- Compact width (`outer`, `splitview-*`): one column at a time, the template's stack. The book page is one scrolling column: the book card, then its notes.
- Regular width: the list and the book page side by side, the list's edge on the fold when held like a book. At 669 pt wide, iOS lays the list over the detail; leave it.
- `BookPage` held like a book (`inner-landscape`): the left page is the book card (title, author, progress bar, status menu, Start Reading); the right page is the notes, newest first, with an add field at the top. Nothing interactive within 20 pt of the fold.
- `SessionTimer` with a horizontal fold (`tabletop`): elapsed time and the book title fill the top half; Pause, +1 page, and End sit in the bottom half, at least 44 pt tall. Without a horizontal fold it is one column.
- Starting a session sets the book to Reading. Ending it adds a `Session` and moves `currentPage` forward by the pages read. Reaching `totalPages` offers Mark as Finished.
- Seed data: 8 books across the three statuses, long and short titles, three with notes, one quote of three lines.

## Stories

```markdown
# Stories

## M1 Core loop

### S-001 Add a book
As the user, I tap + and type a title and author, and the book appears in To Read.
Screens: toRead
Acceptance:
- [unit] BookTitle.clean trims spaces and falls back to "Untitled Book".
- [self] Adding a book creates one Book with status toRead.
- [snap] outer, inner-landscape: the new book shows in the To Read list.
Status: todo

### S-002 Move a book along
As the user, I change a book's status from its page or with a swipe.
Screens: reading, finished
Depends: S-001
Acceptance:
- [self] Setting status to finished sets finishedAt; setting it back clears it.
- [ui] outer: swiping a row shows Start Reading and Finished; its context menu has the same.
- [snap] inner-landscape: the book leaves one list and shows in the other without leaving the page.
Status: todo

### S-003 See the library on any screen
As the user, I see the right layout whether the phone is closed, open, or in Split View.
Screens: reading
Depends: S-001
Acceptance:
- [snap] outer, splitview-left: one column, the list first.
- [snap] inner-landscape: the list fills the left page, the book page the right page, the column edge on the fold.
- [snap] inner: the list shows, beside or over the book page.
- [snap] iphone-27.0: every page renders on an iPhone 18 Pro.
- [manual] splitview-right: the list and the toolbar clear the system buttons on the app's outer edge.
Status: todo

### S-004 Write notes and quotes
As the user, I add a note or a quote to a book from its page.
Screens: book-notes
Depends: S-001
Acceptance:
- [self] A note saves with its page and stays after a restart.
- [snap] outer: notes follow the book card in one column.
- [snap] inner-landscape: notes fill the right page; no text crosses the fold band.
Status: todo

### S-005 Read the book page as two facing pages
As the user, I open the phone like a book and the book page spreads over both halves.
Screens: book
Depends: S-004
Acceptance:
- [snap] inner-landscape: the book card on the left page, notes on the right, nothing interactive within 20 pt of the fold.
- [manual] inner-landscape, half folded: the split follows the fold as it moves.
Status: todo

### S-006 Time a reading session
As the user, I start a session from a book, see the time, and end it with the pages I read.
Screens: session
Depends: S-002
Acceptance:
- [unit] ReadingMath: pages left, percent read, minutes per page, with a table of 10 rows.
- [self] Ending a session adds a Session and moves currentPage forward.
- [snap] outer, inner: the timer and its controls in one column.
- [manual] tabletop: the time on the top half, Pause, +1 page, and End on the bottom half.
- [manual] tent: the time is readable from a meter away.
Status: todo

## M2 Polish

### S-007 Share a quote
As the user, I share a quote from its context menu.
Depends: S-004
Acceptance:
- [manual] outer: the share sheet shows the quote text and the book title.
Status: todo

### S-008 Keep it on my phone
As the user, the app stays on my iPhone Duo past the free Apple ID's 7 days.
Depends: S-003
Acceptance:
- [manual] make deploy prints DEPLOYED and opened on the iPhone.
- [manual] tools/redeploy-agent.sh status shows last exit code = 0 and the profile's expiry.
Status: todo

## Dropped
- Online catalog search and covers: the brief keeps data local.
- Reading goals and streaks: version two.
```

## Gotchas

- The iOS 27.1 simulator runtime runs only the iPhone Duo. Check iOS 27.0 on an iPhone 18 Pro (`APP_DEVICE="iPhone 18 Pro"`); the template's tools create it on first use.
- No script can open, fold, or rotate the Duo simulator. Size-only snapshots cover the inner sizes. Tabletop, tent, and the left and right Split View halves need a person in Device Hub, so their acceptance lines are `[manual]`.
- The fold is a `.division` region only while the Duo is half folded. Flat, there is no region: split at the middle of the window, measured inside `.ignoresSafeArea()` (the template's `FoldSplit`). The open Duo keeps 84 pt of safe area on the right, so the middle of the view or the safe area misses the fold. Never lay out from the hinge angle.
- Flat, a real Duo floats the list over a dimmed book page; half folded, it tiles them. Both are fine. The simulator always tiles at 951 x 669, so check the phone.
- A 3-column split view with no selection shows only an empty detail on a regular width. Start with `columnVisibility` at `.doubleColumn`.
- Notes are scrolling content: they may pass over the fold. The add field and the book card's buttons may not.
- The outer display's safe area is 84 pt on the right, where the status bar and the toolbar buttons stand. A full-width custom bar collides with it.
- A free Apple ID's profile lasts 7 days, and Xcode reuses it until it expires. The deploy agent moves it aside and renews it. Never change the bundle id: the books live in the app's sandbox.
- A widget can't read the books without an App Group, which a free Apple ID can't sign. It stays out of version one.

Done when the app builds with no warnings, `make selftest` passes, the
pose snapshots pass and show the list on the fold held like a book and two
facing pages for a book, every `[manual]` pose line has been checked in
Device Hub or on the phone, and the app opens on the user's iPhone Duo
after `make deploy`.
