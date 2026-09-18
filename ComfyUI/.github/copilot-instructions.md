# Copilot instructions for ComfyUI

## Repository overview

This repository is ComfyUI, a local AI workflow engine for images, video, audio, 3D, and text generation. The core architecture is a node-graph execution system with several clear layers:

- `comfy/` and `comfy_*` packages: model definitions, node behavior, execution primitives, quantization/offload helpers, and core runtime logic.
- `app/`, `api_server/`, `server.py`, `execution.py`: server, API, app lifecycle, queueing, and runtime orchestration.
- `custom_nodes/`, `models/`, `input/`, `output/`, `folder_paths.py`: user-managed assets and filesystem conventions.
- `tests/` and `tests-unit/`: functional and unit coverage for execution and Python behavior.

Keep changes narrow and aligned with the layer that owns the behavior. Do not route UI/API concerns through shared model code or mix execution state with frontend concerns.

## Required repo-specific constraints

Follow the repository rules in `AGENTS.md`:

- Keep edits small and direct; prefer the narrowest fix over broad refactors.
- Preserve existing APIs, workflow compatibility, node names, model-loading behavior, and file layouts unless explicitly changing them.
- Do not add outbound internet requests to core ComfyUI.
- Keep state and capability flags on the object that owns them.
- Do not add compatibility wrappers or dead code paths just to preserve older behavior.
- Prefer existing ComfyUI helpers and optimized ops over custom implementations when they already solve the problem.
- Avoid adding `torch.no_grad`, `torch.inference_mode`, or training/freeze toggles in inference code.
- Use local Python style conventions already present in the file being edited; keep comments sparse and useful.

## Setup and validation commands

Use the commands the repo itself runs in CI:

```bash
# install repo requirements
python -m pip install --upgrade pip
pip install -r requirements.txt

# unit tests
pip install -r tests-unit/requirements.txt
python -m pytest tests-unit

# execution tests
python -m pytest tests/execution -v --skip-timing-checks

# linting
ruff check .

# repo-specific pylint check used in CI for this area only
pylint comfy_api_nodes
```

Notes:

- `pytest.ini` sets `testpaths = tests tests-unit` and `pythonpath = .`.
- `pyproject.toml` configures Ruff to run `E`, `W`, `F`, and targeted security checks (`N805`, `S307`, `S102`, `T`), while ignoring long lines and a few common exceptions.
- The project’s older test docs also mention the inference test flow:

```bash
pip install pytest
pip install websocket-client==1.6.1 opencv-python==4.6.0.66 scikit-image==0.21.0
pytest tests/inference
```

## Running a single test

Prefer the narrowest test possible:

```bash
# single file
python -m pytest tests-unit/path/to/test_file.py -q

# single test by name
python -m pytest tests-unit/path/to/test_file.py::test_name -q

# single test selection with -k
python -m pytest tests-unit -k "some_keyword" -q
```

Use file and test selectors rather than broad suite runs when debugging a specific bug.

## Working style for this repo

- Keep scope small. Most fixes should touch the narrowest code path relevant to the bug or feature.
- Preserve backend behavior, model-loading conventions, and user workflows. Do not silently change node names, checkpoint semantics, or execution contracts.
- If a change crosses layers, prefer a small adapter or boundary mapping rather than leaking one layer’s private concepts into another.
- Reuse existing ComfyUI op and model helpers before introducing custom logic.
- Avoid broad architecture churn; add abstractions only when they remove real duplication or match an existing local pattern.
- Remove dead compatibility branches, obsolete options, and stale fallbacks when they are no longer needed.

## Architecture cues

When editing core code, understand the ownership of the subsystem:

- `comfy/` and `comfy_*`: model code, backend runtime primitives, and graph/execution helpers.
- `app/` and `comfy_api`: web/API surface and app orchestration.
- `execution.py` and `comfy_execution/`: execution orchestration and queue semantics.
- `folder_paths.py`, `extra_model_paths.yaml.example`, and `models/`: model discovery and filesystem conventions.
- `custom_nodes/`: user extensions; keep core repo behavior independent from third-party node code.

Do not make one subsystem “know” about another subsystem’s private identifiers or UI-only concepts unless that boundary is already the right place for them.

## Safety and correctness notes

- Do not add internet telemetry, tracking, analytics, or update/check-in code paths to core ComfyUI.
- Respect dtype, device placement, VRAM/offload, and model compatibility when touching shared runtime or model code.
- Prefer existing ComfyUI optimized kernels/helpers over handwritten duplicates.
- Keep model-detection checks robust and guard all state-dict keys before dereferencing;
  when matching formats, prefer established detectors before newer generic ones.
- Do not use tensors as generic Python data structures or add unnecessary parameters to shared model/helper APIs.

## When in doubt

- Read the closest existing file and follow local patterns before changing APIs or execution behavior.
- Prefer small, reviewable diffs over broad rewrites.
- Validate with the smallest relevant test or lint command, not a full project-wide sweep unless the change truly warrants it.
