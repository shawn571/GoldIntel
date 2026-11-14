# P4-M3 live check 2: 0.6.1-passive, and the 0.6.2 proposal (2026-11-14, session S-075)

STATUS: APPROVED (D-118) and BUILT as 0.6.2-passive (S-076). The user added three requirements: (a) after Configure,
Ignore or Reload Now the next popup waits a full interval; (b) a real Ignore never re-shows it at once; (c) the log
separates the user's clicks from closes the client makes itself. Each has a test and a deliberate-bug check. He clicked
Ignore at some of 300/662/783 s but cannot say which; 0.6.2 makes both cases visible in the log. PR #9 stays unmerged
until 0.6.2 passes.

Files: the account file and the Paladin character file attached in S-075, plus the user's notes and a screenshot of the
Settings window. Read only.

## Passed (user, confirmed in the files where the files can show it)

- Versions; `/gi probe`: `ui.popup`, `ui.reload` and `encounter.events` are ok.
- The popup holds until combat ends. Reload Now reloads the UI on Forever: verified, and the trace shows
  `EVT reminder click=reload` followed by a clean interval end.
- Interval of 820 s: `EVT clock final active=486 idle=333 ... total=820 session=820`.
- Interval of 246 s: `total=246 session=246`.
- `agg check` 0 copper; `agg top` ranks by gold per hour; no frame over 500 ms since 0.6.1.
- Not tested: a boss encounter.

**/reload versus restart:** /reload was enough for 0.6.1 although it added TOC files and events. The rule is updated in
CODE_STANDING_ORDERS.md section 3 (D-117).

## Bug 1: the reminder timer keeps running while the popup is open

**Measured** (interval from 0 s, reminder set to 1 minute; checks every 60 s):

| Time (s) | Line |
|---|---|
| 120.1 | shown |
| 240.4 | shown |
| 300.7 | click=ignore, then shown in the same instant |
| 319.0 | click=configure |
| 602.1 | shown |
| 662.6 | click=ignore, then shown in the same instant |
| 696.8 | click=configure |
| 722.9 | shown |
| 783.2 | click=ignore, then shown in the same instant |
| 819.9 | click=reload |

- Each "shown" comes 60.3 s after the previous "shown". So the timer counts from the moment the popup was shown, not
  from when it closed, and it fires again while the popup is still open.
- The "click=ignore" lines in the same instant as a "shown" are most likely not clicks. When a popup that is already
  open is shown again, the client's popup code first cancels the open one with the reason "override", and 0.6.1
  treated every cancel as Ignore. This is inferred from the client's popup code: please say whether you clicked Ignore
  at those moments.

**Fix:**
1. While the popup is open, the timer does not fire.
2. When the popup closes by any button (Reload Now, Ignore, Configure) or with Escape, the full interval restarts from
   that moment. Ignore therefore snoozes one full interval.
3. A cancel with the reason "override" or "timeout" is not a click. It is logged as `EVT reminder closed reason=<r>`.
4. If combat or an encounter hides the popup, that is not a user action: the popup comes back once it is allowed again,
   and the interval does not restart.

**Tests:**
- No second show while open.
- Ignore, Configure and Escape restart the full interval: no popup again before n minutes after the close, one after.
- A simulated "override" cancel is not counted as Ignore.
- Hidden by combat: shown again after combat, with no new interval.
- Deliberate bugs to be caught: timer counting from the show; override treated as a click.

## Bug 2: the Settings window shows a slider mark, not the real value

`StepIndex(1)` returns the nearest mark, 15, so the window showed "15 minutes: Safe" while the setting was 1. The
setting itself stayed 1 (every "shown" line says `minutes=1`), because merely opening the window saves nothing.

**Fix:**
- The window always shows the real setting, e.g. "1 minute: Safe (set by command; not a slider mark)", with the thumb
  on the nearest mark.
- The setting changes only when you move the slider.
- If the setting changes by command while the window is open, the window updates.

**Tests:** setting 1 → label "1 minute"; setting 75 → "75 minutes: Risky"; opening the window keeps the setting
unchanged; moving the slider saves; a command while the window is open updates the label.

## Bug 3: no "Saved" confirmation

**Fix:**
- Under the explanation, the window shows "Changes are saved as soon as you move the slider."
- After each move it shows "Saved: 60 minutes" in green.
- A "Close" button sits next to the X, so closing does not look like cancelling. Both only close the window; nothing
  is lost.

**Tests:** the Saved text after a move shows the new value; Close hides the window; the setting stays.

## Bug 4: chat lines show "GoldIntel: GoldIntel:"

`Platform.Print` puts `GoldIntel: ` in front of every chat line, and the commands' own texts already begin with
`GoldIntel: `. This was already the case before 0.6.0 (six callers). The record of printed lines in the account file
stores the text without the chat prefix, so it shows the prefix only once.

**Fix:** `Platform.Print` adds the prefix only when the text does not already start with "GoldIntel". Callers stay as
they are.

**Tests:** the chat output of `/gi agg check`, `/gi settings` (fallback line) and `/gi version` carries exactly one
prefix; a line without it gets one.

## Version

- 0.6.2-passive, contract 1.17.0 (additive: reminder close reasons, window texts).
- `/reload` is enough (D-117): no new files and no new events.
- Live check 3 adds the untested boss encounter.
