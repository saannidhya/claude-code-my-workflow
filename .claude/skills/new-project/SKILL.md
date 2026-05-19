---
name: new-project
description: Scaffold a new research project under projects/NN_<slug>/ from projects/_template/. Auto-numbers the project, stamps README with date and git SHA, optionally invokes /interview-me to fill research_spec.md, and registers the project in CLAUDE.md's "Current Projects" table. Use when user says "start a new project on X", "scaffold a project for Y", "/new-project <slug>".
argument-hint: "<slug> [--no-interview]"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "AskUserQuestion"]
disable-model-invocation: true
---

# /new-project

Scaffold a new research project. Use when starting a paper that will live under `projects/NN_<slug>/`.

## When to use

- User says "start a new project on X" / "scaffold a project for Y"
- User explicitly types `/new-project <slug>`
- After `/interview-me` has produced a spec and the user wants to formalize it into a project folder

## When NOT to use

- For exploratory work that doesn't warrant a project (use `explorations/` instead)
- For one-off analyses (use a script in `scripts/R/` or `explorations/`)
- To rename an existing project (use `git mv` + manual CLAUDE.md edit)

## Pre-flight

Verify these before scaffolding:
1. Working tree is clean OR has only unrelated changes (`git status`)
2. `projects/_template/` exists and is complete (`ls projects/_template/`)
3. `CLAUDE.md` has a "Current Projects" table (`grep -A 3 "Current Projects" CLAUDE.md`)

If any check fails, halt and report.

## Inputs

- `<slug>`: required. Snake_case, ≤30 chars, descriptive. Examples: `property_tax_capitalization`, `climate_risk_pricing`, `ibuyer_pricing`.
- `--no-interview`: optional flag. Skip the `/interview-me` invitation.

## Workflow

### Step 1: Validate slug

- Lowercase, snake_case, alphanumeric + underscores only
- ≤30 chars
- Not already used (check `projects/NN_<slug>` for any NN)

If invalid, halt with a clear message.

### Step 2: Determine next project number

```bash
ls projects/ | grep -E "^[0-9]{2}_" | sort | tail -1
```

If output is `03_existing`, next number is `04`. If no projects yet, start at `01`. Format with `printf "%02d"`.

### Step 3: Copy template

```bash
cp -r projects/_template projects/NN_<slug>
```

### Step 4: Substitute placeholders

Across all files in the new project folder, replace:

| Placeholder | Substitution |
|---|---|
| `{{PROJECT_NAME}}` | Title-cased slug (e.g., `Property Tax Capitalization`) |
| `{{PROJECT_SLUG}}` | The slug |
| `{{PROJECT_NUMBER}}` | NN (e.g., `01`) |
| `{{PROJECT_PATH}}` | `projects/NN_<slug>` |
| `{{START_DATE}}` | Today's date (YYYY-MM-DD) |
| `{{START_SHA}}` | Output of `git log -1 --format=%h` |
| `{{ONE_SENTENCE_RQ}}` | Leave as-is for user to fill, or use spec from /interview-me if available |

Use a single Bash-driven sed pass or Python heredoc.

### Step 5: Offer `/interview-me`

Unless `--no-interview` was passed:

> "Project scaffolded at `projects/NN_<slug>/`. Want to run `/interview-me <topic>` now to populate `research_spec.md`?"

If yes, invoke `/interview-me` with the project context (cwd or `--project NN`) so its output lands in `projects/NN_<slug>/research_spec.md`.

### Step 6: Register in CLAUDE.md

Locate the "Current Projects" table in CLAUDE.md. Replace the placeholder row (or append, if real projects already exist) with:

```markdown
| {{PROJECT_NUMBER}} | `{{PROJECT_SLUG}}` | SCOPING | _{{ONE_SENTENCE_RQ}}_ | `projects/NN_<slug>/manuscript/paper.tex` | `projects/NN_<slug>/slides/seminar.tex` |
```

### Step 7: Verify scaffold

Run:
```bash
ls projects/NN_<slug>
grep "{{" projects/NN_<slug>/ -r  # should be empty (or only intentional unfilled fields)
```

### Step 8: Commit

```bash
git add projects/NN_<slug> CLAUDE.md
git commit -m "feat(projects): scaffold NN_<slug>"
```

### Step 9: Suggest next steps

> "Scaffolded `projects/NN_<slug>/`. Suggested next steps:
> 1. Fill in `research_spec.md` (or run `/interview-me` if you haven't)
> 2. Run `/lit-review` to seed `Bibliography_base.bib`
> 3. Open `scripts/R/00_setup.R` and adjust the project-specific imports
> 4. If hypothesis-confirmatory, consider `/preregister --style osf`
> 5. Start with sample data in `01_clean.R` (`USE_SAMPLE = TRUE`)"

## Examples

### Scaffold a new project on property tax capitalization

```
/new-project property_tax_capitalization
```

Creates `projects/01_property_tax_capitalization/` (if no prior projects), all placeholders filled, registers in CLAUDE.md, offers `/interview-me`.

### Scaffold without the interview-me invitation

```
/new-project ibuyer_pricing --no-interview
```

Same as above, but skips the offer.

## Troubleshooting

**Slug rejected:** Check it's lowercase snake_case, ≤30 chars, alphanumeric + `_` only.

**Project number collision:** Should never happen (auto-numbered). If it does, manually inspect `projects/` and `git status`.

**Placeholders not all substituted:** The verification step (`grep "{{"`) catches this. Common causes: a placeholder in a file not enumerated in step 4. Add it to the substitution list and re-run.

**CLAUDE.md "Current Projects" table not found:** The skill expects the exact header `## Current Projects` followed by a markdown table. If you've reformatted CLAUDE.md, restore that section or update this skill.

## Cross-references

- `templates/project-readme.md`, `templates/project-research-spec.md`
- `projects/_template/`
- `.claude/rules/project-lifecycle.md`
- `.claude/skills/interview-me/SKILL.md`
