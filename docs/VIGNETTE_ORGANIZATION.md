# Vignette organization for multiRegFlow 0.2.0

The vignette set is organized as a sequence of long-form teaching blocks
rather than a large number of short and overlapping notes. All package
vignettes are written in English.

| Vignette | Primary responsibility | Main functions |
|----|----|----|
| `v00-overview.Rmd` | scope, package map, datasets and reading order | `mr_capabilities`, `mr_example_data`, `mr_fit`, `mr_validate` |
| `v01-foundations-to-advanced-tutorial.Rmd` | complete foundations-to-advanced workflow | all core functions |
| `v02-diagnostics-influence.Rmd` | residuals, heteroscedasticity, specification and influence | `mr_diagnose`, `mr_influence`, `mr_inference` |
| `v03-collinearity-vif-condition.Rmd` | VIF, tolerance, condition indices and variance decomposition | `mr_collinearity`, `mr_regularize`, `mr_select` |
| `v04-selection-stability.Rmd` | AIC/BIC, best subsets, penalized selection and stability | `mr_select`, `mr_compare` |
| `v05-regularization.Rmd` | ridge, lasso, elastic net and lambda rules | `mr_regularize` |
| `v06-bootstrap-resampling.Rmd` | pairs, residual and wild bootstrap | `mr_bootstrap`, `mr_inference` |
| `v07-importance-effects-shap.Rmd` | standardized beta, partial/semi-partial R2, LMG, SHAP and marginal effects | `mr_importance`, `mr_effects` |
| `v08-flexible-alternatives.Rmd` | robust, quantile, GAM and kernel regression | `mr_fit`, `mr_quantile`, `mr_kernel`, `mr_compare` |
| `v09-validation-comparison.Rmd` | repeated CV, calibration and fair model comparison | `mr_validate`, `mr_compare` |
| `v10-soils-case-study.Rmd` | integrated soil-fertility application | most core functions |
| `v11-plant-science-case-study.Rmd` | integrated physiology and biomass application | most core functions |
| `v12-reporting-audit.Rmd` | Markdown reports, recommendations and reproducibility | `mr_report`, `mr_recommend`, `mr_capabilities` |

## Pedagogical rules

1.  The tutorial in `v01` is the principal starting point.
2.  Topic vignettes deepen one methodological block and avoid
    reproducing the whole tutorial.
3.  Case-study vignettes emphasize interpretation rather than
    introducing many new methods.
4.  OLS remains the reference specification unless a scientific or
    diagnostic reason motivates an alternative.
5.  Selection, importance and prediction are never treated as equivalent
    questions.
6.  Every exported function appears in multiple realistic agronomic
    examples across the vignette set.
7.  Expensive kernel and stability-selection examples may be marked
    `eval = FALSE` in vignettes to keep package builds practical; they
    are executed separately by the local validation workflow.
8.  Synthetic data are explicitly identified as synthetic.

## Coverage target

The manual contains at least three examples for every exported function.
The vignette set also provides at least three distinct calls or contexts
for every exported function, distributed across the tutorial,
methodological vignettes and integrated case studies.
