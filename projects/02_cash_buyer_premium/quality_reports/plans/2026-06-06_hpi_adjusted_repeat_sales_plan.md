# State-HPI-Adjusted Repeat Sales Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or inline execution with tests. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the first scripted HPI-adjusted repeat-sale benchmark for `02_cash_buyer_premium`.

**Architecture:** Keep the heavy data join inside DuckDB: read the existing repeat-sale pair CSV, join purchase and resale years to `data/external/fhfa_state_hpi.parquet`, compute state-HPI-adjusted returns, and write aggregated tables plus a figure. Helper-level R tests cover the return formula and holding-period binning.

**Tech Stack:** R, DuckDB, Arrow parquet, tidyverse, ggplot2, testthat.

---

### Task 1: Helper-Level Tests

**Files:**
- Modify: `projects/02_cash_buyer_premium/scripts/R/tests/test_repeat_sale_helpers.R`
- Modify: `projects/02_cash_buyer_premium/scripts/R/repeat_sale_helpers.R`

- [ ] Add tests for `hpi_adjusted_annualized_log_return()` using known log prices and HPI values.
- [ ] Add tests for `repeat_sale_hold_bin()` using boundary values.
- [ ] Run `Rscript -e "testthat::test_file('projects/02_cash_buyer_premium/scripts/R/tests/test_repeat_sale_helpers.R')"` and verify the new tests fail before implementation.
- [ ] Implement the two helper functions.
- [ ] Re-run the helper tests and verify all pass.

### Task 2: State-HPI Repeat-Sale Script

**Files:**
- Create: `projects/02_cash_buyer_premium/scripts/R/09_repeat_sale_state_hpi_adjusted.R`

- [ ] Read `repeat_sale_pairs_2018_2024.csv` through DuckDB rather than loading it fully into R.
- [ ] Join purchase and resale year/state to `data/external/fhfa_state_hpi.parquet`.
- [ ] Compute raw annualized log return, state-HPI annualized log growth, and HPI-adjusted annualized log return.
- [ ] Winsorize adjusted annualized returns at the 1st and 99th percentiles after materializing the necessary columns.
- [ ] Write summary CSVs by purchase type, purchase year/type, holding-period bin/type, and state/type.
- [ ] Write a figure comparing raw and state-HPI-adjusted annualized returns by purchase type.

### Task 3: Draft Integration

**Files:**
- Create: `projects/02_cash_buyer_premium/manuscript/tables/table3_hpi_adjusted_repeat_sales.tex`
- Modify: `projects/02_cash_buyer_premium/manuscript/paper.tex`
- Create: `projects/02_cash_buyer_premium/quality_reports/specs/2026-06-06_state_hpi_adjusted_repeat_sales.md`

- [ ] Add a manuscript table for the state-HPI-adjusted repeat-sale summary.
- [ ] Add cautious text: this is state-HPI-adjusted, not county-HPI-adjusted and not renovation-adjusted.
- [ ] Add a report memo with exact output locations and the remaining publication gate for county/FHFA or ZIP HPI.
- [ ] Compile the manuscript with `latexmk -pdf -interaction=nonstopmode -halt-on-error paper.tex`.

### Verification

- [ ] Helper tests pass.
- [ ] `09_repeat_sale_state_hpi_adjusted.R` completes and writes expected outputs.
- [ ] Manuscript compiles to PDF.
- [ ] LaTeX log has no undefined citations or references.
