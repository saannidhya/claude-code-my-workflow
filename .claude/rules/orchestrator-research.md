---
paths:
  - "scripts/**/*.R"
  - "explorations/**"
  - "Figures/**/*.R"
---

# Research Project Orchestrator (Simplified)

**For R scripts, simulations, and data analysis** -- use this simplified loop instead of the full multi-agent orchestrator.

## The Simple Loop

```
Plan approved → orchestrator activates
  │
  Step 1: IMPLEMENT — Execute plan steps
  │
  Step 2: VERIFY — Run code, check outputs
  │         R scripts: Rscript runs without error
  │         Simulations: set.seed reproducibility
  │         Plots: PDF/PNG created, correct format
  │         If verification fails → fix → re-verify
  │
  Step 3: SCORE — Apply quality-gates rubric
  │
  └── Score >= 80?
        YES → Done (commit when user signals)
        NO  → Fix blocking issues, re-verify, re-score
```

**No 5-round loops. No multi-agent reviews. Just: write, test, done.**

## Verification Checklist

- [ ] Script runs without errors
- [ ] All packages loaded at top
- [ ] No hardcoded absolute paths
- [ ] `set.seed()` once at top if stochastic
- [ ] Output files created at expected paths
- [ ] Tolerance checks pass (if applicable)
- [ ] Quality score >= 85

## Cross-references

- `.claude/rules/project-lifecycle.md` — project naming (`NN_<slug>`), the 8 status states, scaffold workflow via `/new-project`
- `.claude/rules/corelogic-data-protocol.md` — single-loader-entry-point contract for CoreLogic data
- `.claude/rules/multi-language-conventions.md` — R / Python / Julia role allocation and parquet exchange
