# Variable selection, model search and stability

## Selection is a model-search operation

Variable selection can reduce a candidate model, but it does not erase
the uncertainty created by searching among many specifications. This
matters most when the selected model is subsequently interpreted as if
it had been fixed in advance. `multiRegFlow` therefore exposes selection
methods but labels them as exploratory tools unless the inferential
framework explicitly accounts for the search.

## Example 1: AIC

``` r

soil <- mr_example_data("soil_fertility")
fit <- mr_fit(
  yield_t_ha ~ soil_pH + organic_matter_pct + clay_pct + CEC_cmolc_dm3 +
    available_P_mg_dm3 + exchangeable_K_mg_dm3 + soil_moisture_pct +
    season_rain_mm,
  soil
)
sel_aic <- mr_select(fit, "aic")
sel_aic$selected
#> [1] "organic_matter_pct"    "available_P_mg_dm3"    "exchangeable_K_mg_dm3"
#> [4] "soil_moisture_pct"     "season_rain_mm"
sel_aic$trace
#>              Step Df   Deviance Resid. Df Resid. Dev       AIC
#> 1                 NA         NA       171   56.93915 -189.1753
#> 2       - soil_pH  1 0.04496356       172   56.98412 -191.0332
#> 3 - CEC_cmolc_dm3  1 0.51947317       173   57.50359 -191.3997
#> 4      - clay_pct  1 0.13101352       174   57.63460 -192.9901
```

AIC emphasizes expected predictive information loss. It can favor a
larger model than BIC, particularly with moderate sample sizes.

## Example 2: BIC

``` r

sel_bic <- mr_select(fit, "bic")
sel_bic$selected
#> [1] "organic_matter_pct"    "available_P_mg_dm3"    "exchangeable_K_mg_dm3"
#> [4] "soil_moisture_pct"     "season_rain_mm"
sel_bic$criterion
#> [1] 342.1785
```

BIC penalizes model size more strongly as sample size increases. Neither
AIC nor BIC says that unselected variables are biologically irrelevant.

## Example 3: protect scientifically required terms

``` r

sel_keep <- mr_select(
  fit, "aic",
  keep = c("available_P_mg_dm3", "season_rain_mm")
)
sel_keep$selected
#> [1] "organic_matter_pct"    "available_P_mg_dm3"    "exchangeable_K_mg_dm3"
#> [4] "soil_moisture_pct"     "season_rain_mm"
```

A covariate can be scientifically required even if its individual test
is weak. Examples include a design variable, a known confounder, a
baseline measurement or an environmental exposure that defines the
estimand.

## Best-subset exploration

``` r

if (requireNamespace("leaps", quietly = TRUE)) {
  best <- mr_select(fit, "best_subset")
  best$variables_by_bic
  best$variables_by_adjr2
}
#> [1] "organic_matter_pct"    "available_P_mg_dm3"    "exchangeable_K_mg_dm3"
#> [4] "soil_moisture_pct"     "season_rain_mm"
```

Best subsets enumerates candidate combinations efficiently. It is useful
for teaching how selection criteria can disagree. It becomes
computationally unattractive as the number of predictors grows and still
does not solve post-selection inference.

## Penalized selection

``` r

coll <- mr_example_data("agronomy_collinear")
fit_coll <- mr_fit(yield_t_ha ~ ., coll)
if (requireNamespace("glmnet", quietly = TRUE)) {
  s_lasso_1se <- mr_select(fit_coll, "lasso", lambda = "1se", seed = 20)
  s_lasso_min <- mr_select(fit_coll, "lasso", lambda = "min", seed = 20)
  s_enet <- mr_select(fit_coll, "elastic_net", alpha = 0.5,
                      lambda = "1se", seed = 20)
  s_lasso_1se$selected
  s_lasso_min$selected
  s_enet$selected
}
#> [1] "N_rate_kg_ha"         "N_uptake_kg_ha"       "canopy_N_g_m2"       
#> [4] "NDVI"                 "season_rain_mm"       "soil_mineral_N_mg_kg"
```

The one-standard-error rule usually favors a simpler penalized model
than the minimum-CV-error rule. In correlated predictor groups,
differences between the two solutions are useful evidence about
selection stability.

## Stability selection

``` r

stab <- mr_select(
  fit_coll,
  method = "stability",
  cutoff = 0.75,
  PFER = 1
)
stab$selected
sort(stab$selection_probabilities, decreasing = TRUE)
```

Stability selection asks a different question: which variables continue
to be selected when the data are repeatedly perturbed through
subsampling? The output is therefore more informative than a single
selected set when predictors are numerous or correlated.

## Three levels of evidence

A useful way to interpret selection results is to distinguish:

1.  **scientific necessity**: terms required by design or substantive
    reasoning;
2.  **sample-specific evidence**: terms favored by AIC, BIC or best
    subsets in the current data;
3.  **stability evidence**: terms repeatedly selected across resamples
    or penalized solutions.

A predictor supported by all three levels is different from a predictor
that appears in one stepwise solution only.

## Compare selected models out of sample

Selection criteria do not directly tell us whether predictive
performance improves.

``` r

fit_small <- mr_fit(
  yield_t_ha ~ organic_matter_pct + available_P_mg_dm3 + season_rain_mm,
  soil,
  goal = "prediction"
)
fit_full <- mr_fit(
  yield_t_ha ~ soil_pH + organic_matter_pct + clay_pct + CEC_cmolc_dm3 +
    available_P_mg_dm3 + exchangeable_K_mg_dm3 + soil_moisture_pct +
    season_rain_mm,
  soil,
  goal = "prediction"
)
mr_compare(full = fit_full, reduced = fit_small,
           v = 5, repeats = 3, seed = 20)$prediction
#>      model engine                metric      mean          sd note
#> 1     full    ols                  RMSE 0.6079934 0.014688729 <NA>
#> 2     full    ols                   MAE 0.5013794 0.009693587 <NA>
#> 3     full    ols                    R2 0.3253644 0.032811427 <NA>
#> 4     full    ols calibration_intercept 0.7694107 0.291729301 <NA>
#> 5     full    ols     calibration_slope 0.8646259 0.051608762 <NA>
#> 6  reduced    ols                  RMSE 0.6416261 0.006355416 <NA>
#> 7  reduced    ols                   MAE 0.5293663 0.007653245 <NA>
#> 8  reduced    ols                    R2 0.2489048 0.014878353 <NA>
#> 9  reduced    ols calibration_intercept 0.5555153 0.282092108 <NA>
#> 10 reduced    ols     calibration_slope 0.9022089 0.048970584 <NA>
```

If a smaller model predicts just as well, it may be preferable for
deployment. If the goal is explanation, however, a smaller predictive
model is not necessarily a better scientific adjustment set.

## Recommended reporting

Report the initial candidate set, the selection criterion, variables
forced into the model, the final selected terms, and at least one
stability or validation analysis when selection materially affects the
conclusion. Avoid describing an algorithmically selected model as “the
true model”.
