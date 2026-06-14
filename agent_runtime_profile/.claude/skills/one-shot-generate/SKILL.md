---
name: one-shot-generate
description: "Fully autonomous end-to-end video generation pipeline. Runs ALL stages (asset extraction → episode planning → preprocessing → script → asset sheets → storyboards → videos) without pausing for manual confirmation at each step. Use when user says 'run everything', 'generate all', 'one-shot', 'full pipeline', 'auto run', or wants to kick off the entire workflow hands-free."
---

# One-Shot Generate All

You are the fully autonomous orchestrator. Unlike the standard `manga-workflow`, **you do NOT stop to ask for confirmation between stages**. You run the entire pipeline from start to finish, only pausing if a stage fails.

**Core rules:**
- Read `project.json` first to detect `content_mode` and `generation_mode`
- Check what is already done and skip completed stages (idempotent)
- Dispatch subagents and MCP tools sequentially
- If a stage fails, stop and report the error clearly — do not try to continue past a failure
- Show a single clean summary report at the end

---

## Pre-flight Check

Before starting, read `project.json` and confirm:

1. `content_mode` — `narration`, `drama`, or `ad` (determines pipeline branches)
2. `generation_mode` — `storyboard`, `grid`, or `reference_video` (determines stages 6 & 8)
3. Target episode number — ask the user if not specified, default to the first incomplete episode

Print a single line confirming: `Starting one-shot pipeline for project "{name}", episode {N}, content_mode={mode}, generation_mode={gen_mode}`

---

## Stage 1 — Asset Extraction (Characters / Scenes / Props)

**Skip if**: `characters`, `scenes`, AND `props` in `project.json` are all non-empty.

**Run**:
```
dispatch analyze-assets subagent:
  project_name: {project_name}
  scope: full novel
```

Do NOT wait for user approval after this stage. Proceed immediately to Stage 2.

---

## Stage 2 — Episode Planning

**Skip if**: target episode already has an entry in `project.json.episodes[]` with `ledger_status` == `planned` or `consumed`.

**Run**:
```
mcp__arcreel__plan_episodes({})
```

Do NOT show the episode list for user review. Proceed immediately to Stage 3.

---

## Stage 3 — Episode Preprocessing (Step 1 Intermediate File)

**Skip if**: the correct step1 file already exists for the target episode:
- `generation_mode == reference_video` → `drafts/episode_{N}/step1_reference_units.md`
- `content_mode == narration` → `drafts/episode_{N}/step1_segments.md`
- `content_mode == drama` → `drafts/episode_{N}/step1_normalized_script.md`

**Run** (choose correct subagent based on `generation_mode` + `content_mode`):
- `generation_mode == reference_video` → dispatch `split-reference-video-units`
- `content_mode == narration` → dispatch `split-narration-segments`
- `content_mode == drama` → dispatch the drama preprocessing subagent

Proceed immediately to Stage 4.

---

## Stage 4 — JSON Script Generation

**Skip if**: `scripts/episode_{N}.json` exists AND step1 was NOT modified in this session.

**Run**:
```
dispatch create-episode-script subagent:
  project_name: {project_name}
  project_path: {project_path}
  episode: {N}
```

Proceed immediately to Stage 5.

---

## Stage 5 — Asset Sheet Generation (Characters / Scenes / Props, parallel)

**Skip if**: ALL characters have `character_sheet`, ALL scenes have `scene_sheet`, AND ALL props have `prop_sheet`.

For each asset type that has missing sheets, dispatch in parallel:

```
mcp__arcreel__generate_assets({"type": "character"})   # if any character missing sheet
mcp__arcreel__generate_assets({"type": "scene"})       # if any scene missing sheet
mcp__arcreel__generate_assets({"type": "prop"})        # if any prop missing sheet
```

Wait for all dispatched calls to complete. Proceed to Stage 6.

---

## Stage 6 — Storyboard / Grid Generation

**Skip if**: `generation_mode == reference_video` (no storyboards needed).
**Skip if**: all scenes in `scripts/episode_{N}.json` already have `storyboard_image`.

**Run** based on `generation_mode`:
- `storyboard` → `mcp__arcreel__generate_storyboards({"script": "episode_{N}.json"})`
- `grid` → `mcp__arcreel__generate_grid({"script": "episode_{N}.json"})`

Proceed immediately to Stage 7.

---

## Stage 7 — Video Generation

**Skip if**: all scenes/units in `scripts/episode_{N}.json` already have `video_clip`.

**Run**:
```
mcp__arcreel__generate_video_episode({"script": "episode_{N}.json"})
```

Proceed to Stage 8.

---

## Stage 8 — Narration Audio (narration + storyboard/grid modes only)

**Skip if**: `generation_mode == reference_video` (no narration segments).
**Skip if**: `content_mode != narration`.
**Skip if**: all segments already have `narration_audio`.

**Run**:
```
mcp__arcreel__generate_narration_audio({"script": "episode_{N}.json"})
```

---

## Final Summary Report

After all stages complete, print a clean summary:

```
✅ One-Shot Pipeline Complete — Episode {N}

Stages completed:
  Stage 1 (Assets):      ✅ extracted / ⏭ skipped
  Stage 2 (Planning):    ✅ planned   / ⏭ skipped
  Stage 3 (Preprocess):  ✅ done      / ⏭ skipped
  Stage 4 (Script):      ✅ generated / ⏭ skipped
  Stage 5 (Sheets):      ✅ generated / ⏭ skipped
  Stage 6 (Storyboard):  ✅ generated / ⏭ skipped
  Stage 7 (Video):       ✅ generated / ⏭ skipped
  Stage 8 (Audio):       ✅ generated / ⏭ skipped / ➖ N/A

Next step: Go to the web UI and export your JianYing draft to edit and publish.
```

If any stage failed, replace its row with `❌ FAILED — {error summary}` and stop listing further stages.
