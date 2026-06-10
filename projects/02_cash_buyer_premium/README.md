# Project: Cash Buyer Premium

**Slug:** `cash_buyer_premium`
**Number:** 02
**Started:** 2026-06-05
**Status:** EXPLORATION

---

## Research Question

> What new facts about cash buyers, mortgage buyers, investors, and transaction prices emerge from national CoreLogic transaction microdata, especially around periods when mortgage finance becomes expensive or constrained?

This project starts as a data-first exploration rather than a hypothesis-confirmatory paper. The goal is to use CoreLogic transaction flags and property characteristics to find empirical regularities strong enough to motivate a sharper theory.

## Key Files

- `research_spec.md` - exploratory spec and candidate fact-finding directions
- `scripts/R/00_setup.R` - paths, packages, source URLs
- `scripts/R/01_data_audit.R` - national field coverage and cash/mortgage share audit
- `scripts/R/02_stylized_facts.R` - time-series and buyer-type stylized facts
- `scripts/R/03_property_adjusted_scan.R` - property-adjusted cash/mortgage price-gap scan
- `scripts/R/04_buyer_type_decomposition.R` - property-adjusted cash gaps by ordinary, corporate, investor, and distress cash
- `scripts/R/06_repeat_sale_intermediation.R` - first repeat-sale intermediation scan
- `scripts/R/08_classification_audit.R` - finance-flag and buyer-taxonomy audit
- `scripts/R/09_repeat_sale_state_hpi_adjusted.R` - state-HPI-adjusted repeat-sale benchmark
- `scripts/R/10_clean_cash_gap_decomposition.R` - canonical and clean ordinary cash-gap decompositions
- `manuscript/paper.tex` - preliminary manuscript scaffold for "The Many Meanings of Cash in Housing Markets"
- `scripts/R/_outputs/` - generated tables, plots, and logs

## Status History

| Date | Status | Note |
|---|---|---|
| 2026-06-05 | EXPLORATION | Created as a data-first CoreLogic project independent of property-tax regressivity |
| 2026-06-06 | WRITING | Reframed around "The Many Meanings of Cash in Housing Markets"; added repeat-sale scan, literature/identification memos, and preliminary manuscript scaffold |

## Next Steps

- [x] Audit cash/mortgage/investor/corporate flag coverage by state-year
- [x] Build national monthly stylized facts with mortgage-rate overlay shell; FRED overlay needs a cached retry after timeout
- [x] Search for robust, property-adjusted cash-mortgage gaps in narrow cells
- [x] Identify the most surprising empirical fact and rewrite the spec around it
- [ ] Use `08_classification_audit.R` outputs to lock a canonical buyer taxonomy
- [x] Add state-level FHFA HPI-adjusted repeat-sale benchmark
- [x] Build first clean ordinary-cash and distress-excluded decompositions
- [ ] Add county/ZIP FHFA HPI-adjusted repeat-sale returns
- [ ] Convert the preliminary manuscript into a results-complete draft

## Status definitions

SCOPING -> EXPLORATION -> ANALYSIS -> WRITING -> REVIEW -> SUBMITTED -> R&R -> PUBLISHED
