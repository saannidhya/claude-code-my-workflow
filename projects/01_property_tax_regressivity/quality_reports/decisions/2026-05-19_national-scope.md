# ADR-001: National all-states scope for Property Tax Regressivity paper

**Status:** ACCEPTED
**Date:** 2026-05-19
**Context:** `/interview-me` session, Phase 3 (Data + Setting) question

## Problem

The paper's geographic scope determines what we can identify and where the paper sits in the literature. CoreLogic data is national but converted parquet store had only Ohio when the question was first posed. Four scopes were considered, each with different identification, generalizability, and labor-cost tradeoffs.

## Options considered

### Option A: National, all states

The full national parquet store (~26M residential transactions, 2007-2024). Best for descriptive replication of Berry's regressivity result and for quantifying the national revenue gap. State-level institutional heterogeneity (assessor election, cycle length) becomes the identifying variation rather than a confounder.

**Pro:** Maximum external validity. Identification of the structural primitives (especially cycle-length variation) requires cross-state variation. Direct comparability to Berry (2021), Avenancio-León & Howard (2022), Cohen et al. "Assessing Assessors".
**Con:** Was not feasible at decision time (parquet conversion still running). Larger compute footprint (~26M parcels through structural simulator). State institutional data must be assembled separately.

### Option B: Ohio deep-dive only

Use the existing Ohio baseline (already wrapped to parquet with cousub + place spatial joins from prior Stata-era work). Cleaner identification through Ohio's known features: state-mandated 6-year reassessment cycle with 4 update years; county auditor as elected assessor; well-documented appeals process.

**Pro:** Data ready immediately. Institutional clarity. Researcher has comparative advantage from prior OH work. Faster to first draft.
**Con:** Single-state paper. Lacks cross-state variation that identifies cycle-length and institutional-regime primitives. Limits journal target to NTJ / REE rather than AEJ:Applied / JPubE.

### Option C: Hierarchical (national descriptive + Ohio structural)

National for descriptive replication and revenue-gap quantification (Section 4); Ohio (or Ohio + comparison state) for structural estimation (Section 5).

**Pro:** Best of both worlds. National scope sells the policy story; Ohio focus makes structural estimation tractable.
**Con:** More writing labor (two stories in one paper). Reviewer pushback risk: "Why these state(s) for the structural part?"

### Option D: Cook County, IL only

Strongest external validity for the Berry comparison (his Section I leading examples include Cook County). Joseph Berrios → Fritz Kaegi 2018 sharp regime change as natural experiment for assessor-effect identification. ProPublica 2018 exposé makes Cook the canonical regressivity case.

**Pro:** Tightest causal identification on the assessor-regime change. Rich institutional backstory. Existing data infrastructure.
**Con:** Narrowest scope. National angle entirely lost. Mostly already done by Berry's own Cook County analysis.

## Decision

**Chose:** Option A (National, all states)

**Rationale:** The full parquet conversion completed in the background during the interview (~4.75 hours wall time), removing the feasibility constraint that had favored Option B. With the data ready, Option A dominates: it allows the cross-state institutional variation that identifies the structural primitives (cycle length, elected/appointed regime), produces the strongest journal target (AEJ:Applied / JPubE), and positions the paper directly against Berry (2021) on his own data scale. Option C remains a fallback if structural estimation proves computationally infeasible at full national scale — we can retreat to OH for the structural section while keeping national for the descriptive section.

## Consequences

- Phase 1 (Berry replication) uses national parquet — `load_corelogic_ot(states = NULL, years = 2007:2017)` loads ~26M rows
- Phase 2 (reduced-form mechanism tests) uses national variation — border-MSA design becomes feasible
- Phase 3 (structural estimation) targets all-state moments — six moments listed in spec
- Must acquire: state reassessment cycle data (Lincoln Institute), assessor institutional features (IAAO), ACS tract-level estimates (tidycensus)
- Compute risk: SMM with 5-7 primitives across ~26M simulated parcels likely 4-12 hours per iteration. Mitigation: Julia + Optim.jl, optionally JuMP+Ipopt if model is differentiable
- Ohio baseline files remain useful for cross-validation and as a Section-6 robustness check

## Rejected alternatives — why not

- **B (OH-only):** Loses cross-state identification — the whole structural strategy depends on it. Lower journal target.
- **C (Hierarchical):** Possible fallback if Option A computational scale fails. Held in reserve.
- **D (Cook County):** Already largely covered by Berry; loses the national policy story; would be a small follow-up paper at best.
