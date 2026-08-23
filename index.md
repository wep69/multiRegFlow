# multiRegFlow

`multiRegFlow` provides a guided, auditable workflow for multiple
regression in agricultural, soil and plant sciences. The package keeps
ordinary least squares as a transparent reference model and connects it
to diagnostics, multicollinearity analysis, robust covariance inference,
variable selection, regularization, bootstrap, relative importance,
flexible alternatives and out-of-sample validation.

## Design principle

The package separates two goals that are often mixed in applied
analysis:

- **explanation/inference**: estimate conditional associations and
  uncertainty under a scientifically defined model;
- **prediction**: evaluate how accurately the response can be predicted
  for observations not used during model fitting.

Automated selection is treated as exploratory by default. VIF thresholds
do not trigger automatic variable deletion. Predictive performance is
computed from out-of-fold predictions rather than training fit.

## Core workflow

``` r

library(multiRegFlow)

soil <- mr_example_data("soil_fertility")

fit <- mr_fit(
  yield_t_ha ~ soil_pH + organic_matter_pct + clay_pct +
    available_P_mg_dm3 + exchangeable_K_mg_dm3 +
    soil_moisture_pct + season_rain_mm,
  soil,
  goal = "explanation"
)

mr_diagnose(fit)
mr_influence(fit)
mr_collinearity(fit)
mr_inference(fit, "HC3")
mr_importance(fit, "semi_partial_r2")
mr_recommend(fit)
```

## Selection and shrinkage

``` r

mr_select(fit, "aic")
mr_select(fit, "bic")

coll <- mr_example_data("agronomy_collinear")
fit_coll <- mr_fit(yield_t_ha ~ ., coll)

mr_regularize(fit_coll, "ridge")
mr_regularize(fit_coll, "lasso")
mr_regularize(fit_coll, "elastic_net", alpha = 0.5)
```

## Bootstrap and robust covariance

``` r

mr_bootstrap(fit, R = 2000, type = "pairs")

het <- mr_example_data("agronomy_heteroskedastic")
fit_het <- mr_fit(
  grain_yield_t_ha ~ N_rate_kg_ha + P_rate_kg_ha + soil_water_m3_m3,
  het
)

mr_inference(fit_het, "HC3")
mr_bootstrap(fit_het, R = 2000, type = "wild")
```

## Flexible alternatives

``` r

mr_fit(..., engine = "robust")
mr_fit(..., engine = "quantile", tau = 0.5)
mr_fit(..., engine = "gam")
mr_fit(..., engine = "kernel")
```

Specialized estimation is delegated to established packages such as
`robustbase`, `quantreg`, `mgcv`, `np`, `glmnet`, `stabs`, `sandwich`,
`relaimpo`, `kernelshap` and `marginaleffects`.

## Prediction and comparison

``` r

pred_fit <- mr_fit(
  yield_t_ha ~ organic_matter_pct + available_P_mg_dm3 + season_rain_mm,
  soil,
  goal = "prediction"
)

mr_validate(pred_fit, v = 10, repeats = 5, seed = 123)
```

[`mr_compare()`](https://wep69.github.io/multiRegFlow/reference/multiRegFlow.md)
reports inferential fit and out-of-sample predictive metrics in separate
tables.

## Synthetic teaching datasets

Five frozen datasets are included:

- `soil_fertility`
- `plant_growth`
- `agronomy_collinear`
- `irrigation_nonlinear`
- `agronomy_heteroskedastic`

They are synthetic and intended only for teaching, testing and
reproducible examples.

## Documentation

The package includes 13 English vignettes organized from overview and
foundations to diagnostics, collinearity, selection, regularization,
bootstrap, importance, flexible alternatives, predictive validation,
soil and plant-science case studies, and reporting/audit trails.

## Validation

The source tree includes `LOCAL_VALIDATION.md` and
`VALIDATION_STATUS.md`. The local validation workflow executes package
examples, optional backends, vignette rendering, `R CMD build`, and
`R CMD check --as-cran`.

## Maintainer metadata

The current development source uses `maintainer@multiregflow.invalid` as
an explicit placeholder. Replace it with a verified maintainer email
before CRAN submission or public release.
