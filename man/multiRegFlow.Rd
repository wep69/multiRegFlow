\name{multiRegFlow}
\alias{multiRegFlow}
\alias{mr_fit}
\alias{mr_diagnose}
\alias{mr_influence}
\alias{mr_collinearity}
\alias{mr_select}
\alias{mr_regularize}
\alias{mr_bootstrap}
\alias{mr_validate}
\alias{mr_importance}
\alias{mr_inference}
\alias{mr_effects}
\alias{mr_quantile}
\alias{mr_kernel}
\alias{mr_compare}
\alias{mr_recommend}
\alias{mr_capabilities}
\alias{mr_example_data}
\alias{mr_report}
\title{Guided Multiple Regression for Agricultural Sciences}
\description{
A teaching-oriented and auditable workflow for multiple regression in
agricultural, soil and plant sciences. Ordinary least squares is retained as a
transparent reference model and is connected to diagnostics, collinearity
analysis, robust covariance inference, selection, regularization, bootstrap,
predictive validation, relative importance and flexible alternatives.
}
\usage{
mr_fit(formula, data, goal = c("explanation", "prediction"),
       engine = c("ols", "robust", "quantile", "kernel", "gam"),
       tau = 0.5, ...)
mr_diagnose(x)
mr_influence(x)
mr_collinearity(x)
mr_select(x, method = c("aic", "bic", "best_subset", "lasso",
          "elastic_net", "stability"), alpha = 0.5, keep = NULL,
          seed = 123, lambda = c("1se", "min"), ...)
mr_regularize(x, method = c("ridge", "lasso", "elastic_net"),
              alpha = 0.5, lambda = c("1se", "min"),
              nfolds = 10, seed = 123, ...)
mr_bootstrap(x, R = 999, type = c("pairs", "residual", "wild"),
             seed = 123, conf = 0.95,
             interval = c("percentile", "basic", "normal"))
mr_validate(x, v = 10, repeats = 5, seed = 123)
mr_importance(x, method = c("standardized", "partial_r2",
              "semi_partial_r2", "lmg", "shap"), ...)
mr_inference(x, vcov = c("classical", "HC3", "HC0", "HC1", "HC2",
             "HC4", "HC4m", "HC5", "cluster"), cluster = NULL,
             conf = 0.95)
mr_effects(x, variables = NULL, ...)
mr_quantile(x, tau = c(0.1, 0.25, 0.5, 0.75, 0.9), ...)
mr_kernel(x, ...)
mr_compare(..., validation = TRUE, v = 10, repeats = 3, seed = 123)
mr_recommend(x)
mr_capabilities()
mr_example_data(name = c("soil_fertility", "plant_growth",
                         "agronomy_collinear", "irrigation_nonlinear",
                         "agronomy_heteroskedastic"))
mr_report(x, file = NULL, vcov = c("auto", "classical", "HC3"),
          validation = NULL, v = 5, repeats = 3, seed = 123)
}
\arguments{
\item{formula}{A model formula with a numeric response.}
\item{data}{A data frame.}
\item{goal}{Scientific goal: \code{"explanation"} or \code{"prediction"}.}
\item{engine}{Model engine. OLS is the transparent reference implementation.}
\item{tau}{Quantile or vector of quantiles for quantile regression.}
\item{x}{An object created by \code{mr_fit()}.}
\item{method}{Method-specific option.}
\item{alpha}{Elastic-net mixing parameter.}
\item{keep}{Terms that must remain in stepwise search.}
\item{seed}{Random seed used by resampling or cross-validation methods.}
\item{lambda}{Cross-validation rule used to select lambda.}
\item{nfolds}{Number of folds for penalized regression.}
\item{R}{Number of bootstrap replicates.}
\item{type}{Bootstrap resampling type.}
\item{conf}{Confidence level.}
\item{interval}{Bootstrap interval type.}
\item{v}{Number of cross-validation folds.}
\item{repeats}{Number of cross-validation repetitions.}
\item{variables}{Variables passed to \pkg{marginaleffects}.}
\item{vcov}{Covariance estimator for coefficient inference or report generation.}
\item{cluster}{Cluster identifier vector, column name, or one-sided formula.}
\item{name}{Name of a frozen synthetic teaching dataset.}
\item{validation}{Whether to compute out-of-fold validation.}
\item{file}{Optional Markdown output path.}
\item{...}{Additional arguments passed to a backend.}
}
\value{
Functions return structured lists, data frames, backend model objects, or
\code{mr_fit} objects. \code{mr_report()} returns generated Markdown text
invisibly and optionally writes it to disk.
}
\details{
The package intentionally separates inferential adequacy from predictive
performance. Automated selection is treated as exploratory unless the design and
inferential procedure justify stronger claims. Collinearity is evaluated jointly
using VIF/tolerance, condition indices, variance-decomposition proportions and
scientific context; variables are not automatically deleted based on a single
threshold. Predictive claims are evaluated with out-of-fold predictions.
}
\examples{
## ------------------------------------------------------------------
## Shared synthetic agronomic datasets
## ------------------------------------------------------------------
soil <- mr_example_data("soil_fertility")
plant <- mr_example_data("plant_growth")
coll <- mr_example_data("agronomy_collinear")
het <- mr_example_data("agronomy_heteroskedastic")
nl <- mr_example_data("irrigation_nonlinear")

## mr_example_data(): three examples
head(mr_example_data("soil_fertility"))
head(mr_example_data("plant_growth"))
head(mr_example_data("agronomy_collinear"))

## mr_fit(): three examples
fit_soil <- mr_fit(
  yield_t_ha ~ soil_pH + organic_matter_pct + available_P_mg_dm3 +
    season_rain_mm, soil, goal = "explanation")
fit_plant <- mr_fit(
  biomass_g ~ leaf_area_cm2 + chlorophyll_spad + leaf_N_pct +
    plant_height_cm, plant, goal = "prediction")
if (requireNamespace("robustbase", quietly = TRUE))
  fit_robust <- mr_fit(yield_t_ha ~ N_rate_kg_ha + season_rain_mm,
                       coll, engine = "robust")

## mr_diagnose(): three examples
mr_diagnose(fit_soil)
mr_diagnose(mr_fit(grain_yield_t_ha ~ N_rate_kg_ha + P_rate_kg_ha +
                     soil_water_m3_m3, het))
mr_diagnose(mr_fit(yield_t_ha ~ irrigation_mm + N_rate_kg_ha +
                     mean_temp_C, nl))

## mr_influence(): three examples
head(mr_influence(fit_soil))
head(mr_influence(mr_fit(biomass_g ~ leaf_area_cm2 + chlorophyll_spad +
                           leaf_N_pct + root_mass_g, plant)))
head(mr_influence(mr_fit(grain_yield_t_ha ~ N_rate_kg_ha +
                           soil_water_m3_m3, het)))

## mr_collinearity(): three examples
mr_collinearity(mr_fit(yield_t_ha ~ ., coll))$VIF
mr_collinearity(mr_fit(yield_t_ha ~ soil_pH + organic_matter_pct +
                         clay_pct + CEC_cmolc_dm3, soil))$VIF
mr_collinearity(mr_fit(biomass_g ~ leaf_area_cm2 + chlorophyll_spad +
                         leaf_N_pct + plant_height_cm, plant))$VIF

## mr_select(): three examples
mr_select(fit_soil, "aic")
mr_select(fit_soil, "bic")
if (requireNamespace("leaps", quietly = TRUE))
  mr_select(fit_soil, "best_subset")

## mr_regularize(): three examples
if (requireNamespace("glmnet", quietly = TRUE)) {
  fit_coll <- mr_fit(yield_t_ha ~ ., coll, goal = "prediction")
  mr_regularize(fit_coll, "ridge", nfolds = 5)
  mr_regularize(fit_coll, "lasso", nfolds = 5)
  mr_regularize(fit_coll, "elastic_net", alpha = 0.5, nfolds = 5)
}

## mr_bootstrap(): three examples
mr_bootstrap(fit_soil, R = 40, type = "pairs", seed = 1)
mr_bootstrap(fit_soil, R = 40, type = "residual", seed = 1)
fit_het <- mr_fit(grain_yield_t_ha ~ N_rate_kg_ha + P_rate_kg_ha +
                    soil_water_m3_m3, het)
mr_bootstrap(fit_het, R = 40, type = "wild", seed = 1)

## mr_validate(): three examples
mr_validate(fit_plant, v = 5, repeats = 2, seed = 2)
mr_validate(mr_fit(yield_t_ha ~ available_P_mg_dm3 + season_rain_mm,
                   soil, goal = "prediction"), v = 5, repeats = 2)
if (requireNamespace("robustbase", quietly = TRUE)) {
  vr <- mr_fit(yield_t_ha ~ N_rate_kg_ha + season_rain_mm,
               coll, engine = "robust", goal = "prediction")
  mr_validate(vr, v = 3, repeats = 1)
}

## mr_importance(): three core examples
mr_importance(fit_soil, "standardized")
mr_importance(fit_soil, "partial_r2")
mr_importance(fit_soil, "semi_partial_r2")

## mr_inference(): three examples
mr_inference(fit_het, "classical")
if (requireNamespace("sandwich", quietly = TRUE))
  mr_inference(fit_het, "HC3")
if (requireNamespace("sandwich", quietly = TRUE)) {
  het$block <- rep(seq_len(18), length.out = nrow(het))
  fcl <- mr_fit(grain_yield_t_ha ~ N_rate_kg_ha + P_rate_kg_ha +
                  soil_water_m3_m3, het)
  mr_inference(fcl, "cluster", cluster = "block")
}

## mr_effects(): three examples
if (requireNamespace("marginaleffects", quietly = TRUE)) {
  mr_effects(fit_soil, variables = "available_P_mg_dm3")
  mr_effects(fit_soil, variables = "season_rain_mm")
  mr_effects(fit_plant, variables = "leaf_N_pct")
}

## mr_quantile(): three examples
if (requireNamespace("quantreg", quietly = TRUE)) {
  mr_quantile(fit_het, tau = 0.25)
  mr_quantile(fit_het, tau = 0.50)
  mr_quantile(fit_het, tau = 0.75)
}

## mr_kernel(): three documented examples
\dontrun{
if (requireNamespace("np", quietly = TRUE)) {
  base1 <- mr_fit(yield_t_ha ~ irrigation_mm + N_rate_kg_ha, nl)
  base2 <- mr_fit(yield_t_ha ~ irrigation_mm + mean_temp_C, nl)
  base3 <- mr_fit(yield_t_ha ~ N_rate_kg_ha + mean_temp_C, nl)
  mr_kernel(base1)
  mr_kernel(base2)
  mr_kernel(base3, bwmethod = "cv.aic")
}
}

## mr_compare(): three examples
small_soil <- mr_fit(yield_t_ha ~ available_P_mg_dm3 + season_rain_mm,
                     soil, goal = "prediction")
full_soil <- mr_fit(yield_t_ha ~ organic_matter_pct + available_P_mg_dm3 +
                      exchangeable_K_mg_dm3 + season_rain_mm,
                    soil, goal = "prediction")
mr_compare(full = full_soil, reduced = small_soil,
           v = 5, repeats = 1)
mr_compare(full = full_soil, reduced = small_soil, validation = FALSE)
mr_compare(model_a = fit_soil,
           model_b = mr_fit(yield_t_ha ~ available_P_mg_dm3 +
                              season_rain_mm, soil), validation = FALSE)

## mr_recommend(): three examples
mr_recommend(fit_soil)
mr_recommend(mr_fit(yield_t_ha ~ ., coll))
mr_recommend(mr_fit(yield_t_ha ~ irrigation_mm + N_rate_kg_ha +
                      mean_temp_C, nl))

## mr_capabilities(): three examples
mr_capabilities()
subset(mr_capabilities(), available)
subset(mr_capabilities(), !is.na(package) & package != "")

## mr_report(): three examples
txt <- mr_report(fit_soil)
cat(substr(txt, 1, 250))
txt_classic <- mr_report(fit_soil, vcov = "classical")
cat(substr(txt_classic, 1, 250))
tmp <- tempfile(fileext = ".md")
mr_report(fit_soil, file = tmp)
file.exists(tmp)
}
