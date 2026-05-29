# ADR-003: SMM (Simulated Method of Moments) as the structural estimator

**Status:** ACCEPTED
**Date:** 2026-05-19
**Context:** `/interview-me` session, Phase 4 (Identification). Saani specified "estimated, not calibrated" structural model, and noted: "this is my first time to estimate a structural model though, so I will need a lot of your help." (Saved to memory at `user_first_structural_model.md`.)

## Problem

The Bayesian-assessor structural model in `research_spec.md` has 5-7 primitives, multiple sources of identifying variation, and a likelihood that involves an expectation over the assessor's posterior conditional on a stochastic comparable-sales set. We need to choose an estimator. The choice has implications for code complexity, computational cost, statistical properties, and pedagogical fit for a first-time structural estimator.

## Options considered

### Option A: Calibration

Fix primitives at values informed by prior literature (e.g., set σ²_u based on the variance of CoreLogic residuals in hedonic regressions; set δ from reassessment-cycle event studies in published work). Compute counterfactuals from the calibrated model.

**Pro:** Fast. Transparent. No SE estimation. Easy first paper.
**Con:** Researcher explicitly ruled this out ("estimated, not calibrated"). Referees in economics journals (AEJ:Applied / JPubE) expect estimation when feasible. Reduces the paper to a calibrated counterfactual exercise — closer to a policy report than a research article.

### Option B: Maximum Likelihood Estimation (MLE)

Write down the likelihood of observing the (assessment, sale price) pairs given the parameters, maximize directly. If likelihood has no closed form, use simulated likelihood (importance sampling or Laplace approximation).

**Pro:** Statistically efficient under correct specification. Standard in structural IO / labor.
**Con:** Likelihood for the Bayesian-assessor model has no closed form (involves integrating over comparable-sales sets that depend on transaction density). Simulated likelihood adds complexity. MLE is less forgiving on small-sample misspecification than moment-based methods. Heavy ask for a first structural model.

### Option C: Simulated Method of Moments (SMM)

Match a vector of model-implied moments to data moments by simulation. Estimator minimizes weighted distance between simulated and observed moments.

**Pro:** No need for closed-form likelihood. Moments are conceptually transparent (each moment maps directly to a primitive — easy referee defense). Standard asymptotic theory (Hansen 1982; Pakes & Pollard 1989; Duffie & Singleton 1993). Software stack ready in Julia (`Optim.jl`, `BlackBoxOptim.jl`). Forgiving of model misspecification because we're matching specific moments, not the entire joint distribution. **Pedagogically the right first structural estimator.**
**Con:** Less statistically efficient than MLE under correct specification. Choice of moments and weight matrix affects results — needs careful documentation. Computational cost: each iteration requires simulating the full panel of parcels (~5M+) at trial parameter values.

### Option D: Indirect Inference (II)

Estimate an auxiliary model on the real data; estimate same auxiliary model on simulated data at trial parameter values; match auxiliary-model coefficients. Often used when moments are hard to define but auxiliary regressions are natural.

**Pro:** Sometimes more robust than SMM when the auxiliary model captures key features. Familiar to applied micro researchers.
**Con:** Requires choosing AND defending a "good" auxiliary model on top of the structural model — extra layer of judgment. Slightly more complex to teach than SMM.

### Option E: MPEC (Mathematical Programming with Equilibrium Constraints)

Treat estimation as a constrained optimization problem where the equilibrium conditions of the model are constraints. Allows handling models with fixed-point equilibria efficiently.

**Pro:** Faster than nested-fixed-point methods for models with equilibrium conditions.
**Con:** Our Bayesian-assessor model doesn't have a fixed-point equilibrium structure (the assessor's optimization is single-agent; equilibrium isn't a key concept here). MPEC's value-add is limited. Adds complexity.

## Decision

**Chose:** Option C (SMM)

**Rationale:** SMM matches the model's structure best (no closed-form likelihood, but tractable simulation), maps cleanly to the three-source identification strategy (each of the 6 moments corresponds to a specific primitive or variation source), and is the pedagogically appropriate first-structural estimator. The moment-by-moment correspondence to the identification strategy is the strongest defense against the "your structural estimates ride on assumptions" critique — each estimate has a transparent variation source.

For Saani's first structural model, SMM is materially less complex to implement, debug, and defend than MLE / II / MPEC. The standard reference (Adda & Cooper 2003 "Dynamic Economics" Ch. 4; Aguirregabiria & Mira 2010 J Econometrics survey) is excellent. Julia's `Optim.jl` ecosystem and DuckDB.jl for parcel-level simulation give us a clean workflow.

## Consequences

### Implementation plan

```
projects/01_property_tax_regressivity/scripts/julia/
├── 01_model.jl       Bayesian assessor model (closed-form posteriors)
├── 02_simulator.jl   Simulate panel of parcels given parameters
├── 03_moments.jl     Compute 6 moments from simulated and observed data
├── 04_smm.jl         SMM optimizer (2-stage: identity W → optimal W)
├── 05_se.jl          Block bootstrap, jurisdiction-year clusters, 500 reps
└── 06_counterfactuals.jl  Welfare counterfactuals (annual reassess, costless appeals, all-appointed)
```

### Workflow conventions

- **Two-stage SMM:** first stage with identity weight matrix; second stage with optimal weight matrix from first-stage residuals
- **Optimizer:** `Optim.jl` BFGS for the moment-distance objective (smooth); fallback to `BlackBoxOptim.jl` differential evolution if local optima are a concern
- **Standard errors:** block bootstrap on jurisdiction-year clusters, 500 replications. Sandwich SE as a cross-check
- **Identification check:** numerical Jacobian of moment vector w.r.t. parameter vector at estimated point; check rank = number of parameters
- **Over-identification test:** Hansen J-statistic with 1 degree of freedom (6 moments, 5 primitives)
- **Reporting:** parameter point estimates with bootstrap SE; J-stat with p-value; identification-strength F-stats per moment; sensitivity to weight-matrix choice

### Computational risk

- ~5M-26M simulated parcels per iteration
- ~50-200 iterations per optimization run
- Estimated wall time: 4-12 hours per full run on workstation; can parallelize moments across cores
- Mitigation: develop on a state-level subsample (Ohio ~5M parcels), verify convergence, then scale to national

### Pedagogical commitments (for Saani's first structural model)

- Walk through SMM theory step-by-step before writing code: identification, moment selection, weight matrix, standard errors, J-test
- Code with explanatory comments — treat the Julia source as a teaching artifact
- Recommended parallel reads: Adda & Cooper Ch. 4 (foundational); Aguirregabiria & Mira 2010 *J. Econometrics* (survey); Wolak's classic CRSP paper as an applied SMM template
- Cross-validate the SMM estimates against a calibrated benchmark: do the SMM-estimated primitives produce moments close to the data moments? (Sanity check)

## Rejected alternatives — why not

- **A (Calibration):** User explicitly ruled out.
- **B (MLE):** No closed-form likelihood; simulated MLE adds layer of complexity that isn't pedagogically appropriate for first-structural; less forgiving than SMM on small-sample.
- **D (Indirect Inference):** Adds an auxiliary-model layer with no offsetting benefit for this application; moments map naturally to primitives so SMM is the cleaner fit.
- **E (MPEC):** Our model lacks the fixed-point equilibrium structure where MPEC's value-add lies.
