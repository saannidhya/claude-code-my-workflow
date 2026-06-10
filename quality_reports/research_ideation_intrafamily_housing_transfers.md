# Research Ideation: Non-Market (Intra-Family) Housing Transfers and the Supply of Homes

**Date:** 2026-06-09
**Input:** CoreLogic national deeds (2007–mid-2024, ~160M records) + property characteristics snapshot. Verified facts: residential intra-family transfers run 1.9–3.6M/yr vs 3.5–6.6M/yr arm's-length sales; CA Prop 19 anticipation surge + post-deadline collapse clearly visible in raw monthly counts.
**Target:** Top-5 general-interest journal, Glaeser-style (new facts + transparent identification + welfare framing).

## Overview

A large share of American homes change hands without ever touching a market. Deeds
data record these events — quitclaims between relatives, transfers into family
trusts, executor deeds out of estates — but the literature on housing supply,
turnover, and affordability is built almost entirely on *arm's-length sales*.
Verified counts in our data: residential intra-family transfers are roughly **half
as numerous as market sales** every year (1.9–3.6M vs 3.5–6.6M). If the homes that
pass within families systematically fail to reach the market — held by absentee
heirs, under-occupied, under-maintained — then the family is a quantitatively
first-order, and essentially undocumented, institution of housing allocation.

Tax policy subsidizes this channel: stepped-up basis at death, and (until 2021)
California's parent-child assessment exclusion, which let heirs inherit not just
the house but the parent's (often decades-old) property-tax base. Proposition 19
(passed Nov 3, 2020; parent-child exclusion provisions effective Feb 16, 2021)
abruptly narrowed that exclusion to owner-occupied primary residences (with a
value cap), creating a sharp, observable natural experiment in the tax price of
keeping a house in the family.

## Research Questions

### RQ1: How large is the non-market intra-family channel of US housing turnover, and how has it evolved 2007–2024? (Feasibility: High)

**Type:** Descriptive
**Paper type:** descriptive (measurement + new facts)

**Hypothesis:** Intra-family transfers are 30–50% the volume of market sales; rising over time as the homeowner population ages; concentrated in older owners (senior-exemption parcels), older housing, and low-turnover neighborhoods.

**Identification Strategy:** None needed (measurement). Key methodological contribution: a name-based taxonomy separating (a) true inter-person family transfers (same-surname buyer/seller), (b) trust self-transfers (estate-planning, not a change in control), (c) estate/probate deeds, (d) other non-arm's-length events (divorce, title corrections). Validate against deed type (quitclaim share), price (zero/nominal consideration), and state institutional differences.

**Data Requirements:** OT deeds with names + flags (verified available); prop snapshot for property/owner attributes (verified available).

**Potential Pitfalls:**
1. Flag noise: `interfamily_related_indicator` includes trust self-transfers — mitigate with the name taxonomy; report bounds.
2. County recording heterogeneity — mitigate with within-county comparisons and coverage audits.

**Related Work:** Mostly absent — closest are studies of housing bequests in survey data (HRS-based), heirs' property reports, and the assessor-data literature. (NOVELTY CLAIM — to verify.)

---

### RQ2: What happens to a home after a family transfer — does it return to the market, and who holds it? (Feasibility: High)

**Type:** Correlational / Descriptive-dynamic
**Paper type:** descriptive + reduced-form (hazard analysis)

**Hypothesis:** Homes received via family transfer return to the arm's-length market far more slowly than purchased homes; they are more likely to become absentee-held (buyer mailing address ≠ property address).

**Identification Strategy:** Within-property event linkage via `clip`: for each transfer event, measure time-to-next-arm's-length-sale (Kaplan-Meier / discrete hazard), conditioning on tract, year, property characteristics. Descriptive contrast, not causal — selection acknowledged and embraced (the selection IS the fact: families keep the homes they inherit).

**Data Requirements:** 41.5M multi-event clips (verified); absentee detection via mailing vs situs (verified available).

**Potential Pitfalls:**
1. Right-censoring at mid-2024 — standard survival tools handle.
2. Multi-parcel / re-recording noise — filter to single-parcel residential with valid dates.

**Related Work:** Turnover/mobility literature (e.g., lock-in studies); no national deeds-based post-inheritance trajectory study known. (NOVELTY CLAIM — to verify.)

---

### RQ3: Does the tax price of keeping a home in the family causally affect whether inherited homes reach the market? (CA Prop 19) (Feasibility: High)

**Type:** Causal
**Paper type:** reduced-form (event study + DiD)

**Hypothesis:** Removing the parent-child assessment exclusion for non-owner-occupied homes (i) caused massive retiming (bunching of transfers before Feb 16, 2021 — verified visible), (ii) reduced the steady-state volume of family transfers, and (iii) increased the rate at which inherited homes are subsequently sold on the market (heirs who must pay market-value taxes keep fewer homes).

**Identification Strategy:**
- **Method:** Event study + DiD.
- **Treatment:** CA parent-child transfers after Feb 16, 2021.
- **Controls:** (a) other large states (TX, FL, NY, …) for transfer volume; (b) within CA: arm's-length sales as a within-state control series; (c) for post-transfer sale hazard: pre-2021 CA family-transfer cohorts vs post-2021 cohorts, benchmarked against the same cohort contrast in non-CA states (triple difference).
- **Key assumption:** Parallel trends in family-transfer propensity and post-transfer sale hazard between CA and control states absent Prop 19; COVID-period shocks common across states (test with placebo states and pre-trends).

**Data Requirements:** All verified available.

**Potential Pitfalls:**
1. COVID + 2020 estate-planning surge confounds the anticipation window — separate retiming (bunching) from level effects using post-2022 steady state.
2. Prop 19's other provision (portability for 55+) affects CA arm's-length volume — keep outcomes disjoint (family transfers; post-inheritance sale hazard of pre-period cohorts).
3. CA trust prevalence — name taxonomy distinguishes parent-child deeds from trust administration.

**Related Work:** Prop 13 lock-in (Ferreira 2010 JPubE); transfer-tax retiming (Slemrod et al. on RE transfer taxes; Best & Kleven 2018 on UK stamp duty); CA LAO policy reports on Prop 19. No academic causal evaluation of Prop 19's inheritance provisions at scale known. (NOVELTY CLAIM — to verify.)

---

### RQ4: Through what channel does the family hold-out matter — under-utilization (absentee/vacancy) and misallocation? (Feasibility: Medium-High)

**Type:** Mechanism
**Paper type:** reduced-form + descriptive

**Hypothesis:** Family-transferred homes are disproportionately absentee-held and under-occupied relative to observationally identical purchased homes in the same tract; the gap is larger where the implicit tax subsidy (assessment gap) is bigger.

**Identification Strategy:** Within-tract comparison of post-transfer ownership outcomes (absentee, owner-occupancy code, subsequent rental conversion proxies) between family-received and market-purchased homes; dose-response in CA using the pre/post Prop 19 variation as the shifter of the subsidy.

**Potential Pitfalls:**
1. Occupancy measured from snapshot (current state) — restrict to recent transfers; use mailing-address divergence which updates with taxroll.
2. Vacancy proxy (`situs_delivery_point_validation_vacant_indicator`) coverage to be audited.

**Related Work:** Misallocation-of-housing literature (e.g., Glaeser & Luttmer 2003 AER on rent control misallocation). Family-channel version unstudied. (NOVELTY CLAIM — to verify.)

---

### RQ5: Policy: How much housing supply would flow to market if the tax subsidy to dynastic holding were removed nationally? (Feasibility: Medium)

**Type:** Policy / counterfactual
**Paper type:** reduced-form extrapolation with explicit assumptions (no structural model in v1)

**Hypothesis:** Scaling the Prop 19 hazard response to the national stock of family-held homes implies a supply flow equivalent to a meaningful share (order 1–5%) of annual listings.

**Identification Strategy:** Transparent back-of-envelope: Prop 19 causal hazard shift × national family-transfer stock, with bounds. Glaeser-style welfare framing rather than structural estimation.

**Potential Pitfalls:** External validity of CA elasticity; state property-tax institutions differ (acquisition-value assessment is CA-specific — most states reassess regularly, so the subsidy is smaller; this makes the national number a *lower* bound on CA-type institutions and an *upper* bound elsewhere — present as range).

---

## Ranking

| RQ | Feasibility | Contribution | Priority |
|----|-------------|--------------|----------|
| 1 | High | High (new national facts, new taxonomy) | 1 |
| 2 | High | High (the "family lock" fact) | 2 |
| 3 | High | Very High (clean causal anchor) | 3 (the paper's engine) |
| 4 | Medium-High | Medium-High (mechanism) | 4 |
| 5 | Medium | Medium (framing/welfare) | 5 (short section) |

**Paper architecture (Glaeser-style):** RQ1+RQ2 = Section of big new facts ("the parallel, non-market housing market"); RQ3 = causal core (Prop 19 bunching + DiD + post-inheritance hazard); RQ4 = mechanism; RQ5 = brief welfare/policy arithmetic. One paper, five exhibits.

## Suggested Next Steps

1. Scaffold `projects/03_family_homes/`; freeze the name-based taxonomy spec before any regressions.
2. `/lit-review` on (i) intergenerational housing transfers, (ii) Prop 13/19 and lock-in, (iii) transfer-tax timing responses, (iv) housing misallocation.
3. Verify Prop 19 institutional details (effective dates, $1M cap, owner-occupancy requirement) against primary sources (CA BOE).
4. Audit `situs_delivery_point_validation_vacant_indicator` and owner-occupancy coverage before promising RQ4.

## Verification status

PENDING — claim-verifier dispatch follows (novelty claims; Prop 19 institutional details; related-work citations).
