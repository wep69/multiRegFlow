test_that("AIC and BIC selection return traces and selected terms", {
  d <- mr_example_data("soil_fertility")
  fit <- mr_fit(yield_t_ha ~ soil_pH + organic_matter_pct + clay_pct +
                  available_P_mg_dm3 + exchangeable_K_mg_dm3 + season_rain_mm, d)
  a <- mr_select(fit, "aic")
  b <- mr_select(fit, "bic")
  expect_s3_class(a, "mr_selection")
  expect_s3_class(b, "mr_selection")
  expect_true(is.data.frame(a$trace))
  expect_true(is.character(a$selected))
})

test_that("stepwise keep terms are retained", {
  d <- mr_example_data("soil_fertility")
  fit <- mr_fit(yield_t_ha ~ soil_pH + organic_matter_pct + clay_pct +
                  available_P_mg_dm3 + season_rain_mm, d)
  z <- mr_select(fit, "aic", keep = c("available_P_mg_dm3", "season_rain_mm"))
  expect_true(all(c("available_P_mg_dm3", "season_rain_mm") %in% z$selected))
})

test_that("best subsets identifies candidate sets", {
  skip_if_not_installed("leaps")
  d <- mr_example_data("soil_fertility")
  fit <- mr_fit(yield_t_ha ~ soil_pH + organic_matter_pct + clay_pct +
                  available_P_mg_dm3 + season_rain_mm, d)
  z <- mr_select(fit, "best_subset")
  expect_true(length(z$variables_by_bic) >= 1)
  expect_true(length(z$variables_by_adjr2) >= 1)
})

test_that("regularization exposes CV and selected coefficients", {
  skip_if_not_installed("glmnet")
  d <- mr_example_data("agronomy_collinear")
  fit <- mr_fit(yield_t_ha ~ ., d)
  ridge <- mr_regularize(fit, "ridge", nfolds = 5, seed = 5)
  lasso <- mr_regularize(fit, "lasso", nfolds = 5, seed = 5)
  enet <- mr_regularize(fit, "elastic_net", alpha = .5, nfolds = 5, seed = 5)
  expect_true(ridge$lambda_1se > 0)
  expect_true(is.data.frame(ridge$cv))
  expect_true(is.character(lasso$selected))
  expect_true(is.character(enet$selected))
})

test_that("penalized selection respects lambda rule", {
  skip_if_not_installed("glmnet")
  d <- mr_example_data("agronomy_collinear")
  fit <- mr_fit(yield_t_ha ~ ., d)
  a <- mr_select(fit, "lasso", lambda = "1se", seed = 3)
  b <- mr_select(fit, "lasso", lambda = "min", seed = 3)
  expect_identical(a$lambda_rule, "1se")
  expect_identical(b$lambda_rule, "min")
})
