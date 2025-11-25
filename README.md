<h1> Guelph Schedule Exporter (Chrome Extension) </h1>

Export your University of Guelph Self-Service schedule to ICS or send it straight into Google/Outlook calendars.

---

<h2> Table of Contents </h2>

- [Setup](#setup)
- [Usage](#usage)
- [Key Features](#key-features)
- [How It Works](#how-it-works)
- [Provider Notes](#provider-notes)
- [File Map](#file-map)
- [Testing](#testing)
- [Future Improvements](#future-improvements)

---

## Setup

1. Install dev deps for tests (extension itself is bundle-free):
   ```sh
   npm install
   ```
2. In Chrome/Edge, open `chrome://extensions`, toggle **Developer mode**, then **Load unpacked** pointing to this repo root.
3. (Optional) Open the extension **Options** page to override Google/Outlook OAuth client IDs stored in `chrome.storage.local`.

## Usage

1. Sign in to `https://colleague-ss.uoguelph.ca` and open your **PrintSchedule** page so the content script can see the embedded `result` object.
2. Click the extension icon to open the popup. It will auto-detect available terms and list them as toggleable cards.
3. Choose one or more actions:
   - **Download ICS** - generates `schedule.ics` locally.
   - **Google Calendar** - interactive `chrome.identity` OAuth, then job-based import via the Calendar REST API.
   - **Outlook Calendar** - Microsoft identity + Graph Calendar import.
4. Press **Run Selected**. Progress and per-provider results show inline; errors remain expandable for debugging.
5. Need a walkthrough? Use the popup help link for a quick primer on term selection and provider flows.

## Key Features

- **Zero-copy extraction** - content script injects `src/injected-page.js` to post the page's `result` object; falls back to inline-script parsing when needed.
- **Term-aware normalization** - filters to registered/active sections, keeping multi-instructor listings and start/end dates consistent for recurrence rules.
- **ICS generator** - weekly RRULEs with cutoff handling, deterministic UIDs, and local-time DTSTART/DTEND formatted for calendar imports.
- **Direct imports** - Google and Outlook providers run inside the service worker with progress-tracked jobs and persistent status in `chrome.storage`.
- **Inline troubleshooting** - popup renders per-provider result cards with copy-to-clipboard JSON for quick bug reports.

## How It Works

1. **Page capture** - `src/content.js` checks schedule heuristics, injects a page script to read `window.result`, and answers `extractSchedule` messages from the popup.
2. **Normalization** - `src/ics-generator.js`'s `generateEventsFromRawData` flattens term data into consistent event objects (dates, times, days, instructors, credits).
3. **Outputs** - the same normalized events feed ICS download (`generateICSFromRawData`) and provider imports (Google/Outlook `importEvents`).
4. **Background jobs** - `src/background.js` spawns long-running imports, persists progress to `chrome/storage/local`, and supports polling via `queryJob` from the popup UI.
5. **UI flow** - `src/popup.js` wires term selection, option cards, and result rendering; `options.html/js` persist alternate OAuth client IDs for testing.

## Provider Notes

- **Google** (`src/google.js`) - uses `chrome.identity/getAuthToken`, validates scopes with `tokeninfo`, creates or reuses a dedicated calendar, and batches VEVENT payloads with recurrence when available.
- **Outlook** (`src/outlook.js`) - mirrors the same normalized event shape, authenticates with Microsoft identity endpoints, and writes to the signed-in user's default calendar via Graph.
- **Auth cleanup** - the options page exposes stored client IDs; `google.js` also includes helpers to clear cached tokens when debugging consent prompts.

## File Map

| Component          | Path                  | Purpose                                             |
| ------------------ | --------------------- | --------------------------------------------------- |
| Content script     | `src/content.js`      | Detects schedule pages and extracts `result`.       |
| Injected helper    | `src/injected-page.js` | Runs in page context to post schedule data.         |
| Popup UI           | `src/popup.js`         | Term selection, action toggles, job polling/results.|
| ICS + normalization| `src/ics-generator.js`| Builds normalized events and ICS text.              |
| Background worker  | `src/background.js`   | Manages import jobs and storage.                    |
| Google provider    | `src/google.js`       | Calendar REST auth + event creation.                |
| Outlook provider   | `src/outlook.js`      | Microsoft Graph auth + event creation.              |
| Options page       | `src/options.js`      | Persist alternate client IDs and show help.         |

## Testing

- Run mocha suite: `npm test`
- Fixtures under `tests/fixtures/` cover multi-instructor cases, ICS helpers, and OAuth flow mocks.

## Future Improvements

1. Auto-detect and display overlapping meetings before export/import.
2. Allow selecting a target calendar name (rather than the hard-coded defaults) in the popup.
3. Add a dry-run mode that only validates schedule parsing and shows a diff preview.
