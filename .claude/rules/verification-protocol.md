---
paths:
  - "projects/**/*.tex"
  - "projects/**/scripts/**/*.R"
  - "Slides/**/*.tex"
---

# Task Completion Verification Protocol

**At the end of EVERY task, Claude MUST verify the output works correctly.** This is non-negotiable. Evidence before assertions — never claim "compiles" or "runs" without having run the command and read its output.

## For LaTeX / Beamer (manuscripts + seminar slides)
1. Compile with XeLaTeX (manuscripts: 3-pass + bibtex; slides: single pass) and check the exit code.
2. Grep the log for undefined citations (errors) and count `Overfull \hbox` warnings.
3. Confirm the PDF was generated and is non-empty.
4. For figures pulled from R, confirm the referenced figure files exist.

## For R Scripts
1. Run `Rscript projects/NN_<slug>/scripts/R/filename.R`.
2. Verify output files (`.rds`, `.parquet`, tables, figures) were created with non-zero size.
3. Spot-check estimates for finiteness and reasonable magnitude.
4. **Guard against silent degeneracy:** an empty/near-empty estimation sample, an all-NA column, or a zero-row join can let a script "succeed" while producing a meaningless result. A clean exit is necessary but not sufficient — confirm `nobs`/row counts are in the expected range.

## For Bibliography
- Every `\cite` / `\citet` / `\citep` key in a modified `.tex` file must have an entry in `Bibliography_base.bib`.

## Common Pitfalls
- **Assuming success**: always verify output files exist AND contain sensible content.
- **Degenerate samples**: confirm row counts / `nobs` are in the expected range before trusting an estimate.
- **Stale derived data**: if a script reads a cached `.parquet`, confirm the cache reflects the current upstream script.

## Verification Checklist
```
[ ] Command actually run; exit code checked
[ ] Output file created, non-zero size
[ ] No compilation / run errors; citations resolve
[ ] Estimates finite, sample non-degenerate
[ ] Results reported to user with evidence
```
