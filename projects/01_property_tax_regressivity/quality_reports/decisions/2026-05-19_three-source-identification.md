# ADR-002: Three-source identification strategy for structural primitives

**Status:** ACCEPTED
**Date:** 2026-05-19
**Context:** `/interview-me` session, Phase 4 (Identification) question. Saani explicitly asked: "think deeply yourself and make a judgment on the most novel, creative and defensible identification strategy."

## Problem

The structural model has 5 primitives (σ²_u, κ, λ, δ, c_appeal) plus an appeals-wealth-elasticity (α₂). No single instrument or natural experiment cleanly identifies all of them. The choice is whether to (a) restrict the model to fewer primitives identifiable from one instrument, (b) use a single instrument with reduced-form auxiliary regressions for the others (light structural), or (c) build a multi-source identification strategy that pins down each primitive with its own variation source.

## Options considered

### Option A: Single instrument — Reassessment cycle length (cross-state)

Use state-level variation in mandated reassessment cycle as the single exogenous source. State law sets cycles (MA annual, IL 4-year, OH 6-year) decades ago and is plausibly exogenous to current property markets.

**Pro:** Clean ID story. Easy to explain to referees. One robustness section needed (cycle changes exogenous).
**Con:** Identifies only the info-decay parameter δ. Other primitives (κ, λ, c_appeal) must be calibrated externally or set by assumption — referees will object that the welfare conclusions ride on assumptions, not estimates.

### Option B: Single instrument — Cook County 2018 assessor turnover (event study)

Berrios → Kaegi as a sharp regime change. Estimate model on Cook County only; compute event-study counterfactuals for surrounding counties as treatment-spillover check.

**Pro:** Tightest causal identification on a single mechanism (assessor effect). Rich institutional backstory. Existing media + ProPublica coverage gives the paper a "narrative hook."
**Con:** Kills national scope. Identifies assessor objective (λ) but not info technology (κ, δ) or appeals (c_appeal). Reduces the paper to a Cook-County case study.

### Option C: Single instrument — Building permit data as observability proxy

Use building permits as a direct measurement of attributes "observable to the assessor" (permits are filed with municipality, available to assessor) vs "unobservable" (un-permitted renovations).

**Pro:** Conceptually beautiful — directly measures the Berry mechanism.
**Con:** Permit data isn't in CoreLogic. Would require jurisdiction-by-jurisdiction FOIA. Heterogeneous compliance with permitting rules across cities. Not feasible for v1 of the paper.

### Option D: Three-source identification (recommended in the interview)

Combine three sources of exogenous variation, each pinning a different primitive:

1. **Cross-state reassessment cycle length** (border-MSA design, Dube-Lester-Reich 2010 style) → δ
2. **Within-jurisdiction tract transaction density** (Bartik IV via ACS housing-stock age × family-lifecycle composition) → κ
3. **Cross-jurisdiction assessor institutional regime** (elected vs. appointed, term length, ratio-study requirements; treated as exogenous via state law persistence) → λ

Plus auxiliary identification of appeals technology (c_appeal, α₂) via tract income × assessment-ratio variation; plus the novel transaction-frequency mechanism (H6) as a mediator-variable test.

**Pro:** All five primitives have a defensible identifying source. Each source has methodological precedent in the literature. Most novel: no existing paper has used border-MSA cycle-length variation for assessor info decay. The combination allows separate identification of mechanisms that the literature has only conflated.
**Con:** Three identification stories to defend in one paper — more writing labor, more potential referee objections per source. Compute scale risk on the SMM optimizer with six moments.

## Decision

**Chose:** Option D (Three-source identification)

**Rationale:** The structural model has 5+ primitives and the paper's core contribution is *quantitatively decomposing mechanisms*. Single-instrument options collapse the contribution to a one-mechanism story we don't yet believe is right. Option A (cycle length alone) would force us to assume away the mechanisms (institutions, appeals) that may turn out to dominate empirically — defeating the purpose. Option B (Cook County) gives up national scope. Option C (permits) isn't feasible without permits-data acquisition. Option D matches the model's complexity to the data's variation and is the only strategy that can settle which mechanism dominates — which IS the paper.

The novelty defense is strong: the border-MSA cycle-length design (Source 1) has not been applied to property assessment in any paper we are aware of; the Bartik shift-share for tract transaction density (Source 2) is a methodologically standard IV applied to a non-standard endogenous variable; the elected-vs-appointed institutional comparison (Source 3) connects to Besley & Coate (2003 AER) on political economy of regulators.

## Consequences

- Three identifying-variation data sources to assemble: (1) state cycle length, (2) ACS housing stock + lifecycle, (3) IAAO + state SecState assessor institutional features
- Each source gets a "first-stage validation" section in the manuscript: cycle-length border-MSA balance test; Bartik shift-share first-stage F-stat; institutional persistence test
- Six SMM moments to match (one per primitive plus a second cycle-length moment for over-identification)
- Standard errors via block bootstrap on jurisdiction-year clusters; over-identification test for the moments
- Identification verified by Jacobian rank check at estimated parameters (numerical derivatives) — Saani will need step-by-step guidance on this (see `user_first_structural_model.md` memory)
- Manuscript Section 5 (structural) will be 2-3x longer than a single-instrument paper; allocate accordingly in the timeline

## Rejected alternatives — why not

- **A (cycle length alone):** Identifies δ but assumes away κ, λ, c_appeal — defeats the mechanism-decomposition purpose.
- **B (Cook County):** Loses national scope; produces a different paper.
- **C (permits):** Not feasible without separate FOIA acquisition; deferred to v2 paper or follow-up.
