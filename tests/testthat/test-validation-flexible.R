test_that("OLS validation returns out-of-fold metrics and calibration", {
  d <- mr_example_data("soil_fertility")
  fit <- mr_fit(yield_t_ha ~ organic_matter_pct + available_P_mg_dm3 +
                  season_rain_mm, d, goal = "prediction")
  z <- mr_validate(fit, v = 5, repeats = 2, seed = 4)
  expect_equal(nrow(z$metrics), 2)
  expect_true(all(is.finite(z$predictions$predicted)))
  expect_true(all(c("calibration_intercept", "calibration_slope") %in% z$summary$metric))
})

test_that("robust and quantile engines can be cross-validated", {
  skip_if_not_installed("robustbase")
  skip_if_not_installed("quantreg")
  d <- mr_example_data("agronomy_heteroskedastic")
  rob <- mr_fit(grain_yield_t_ha ~ N_rate_kg_ha + P_rate_kg_ha +
                  soil_water_m3_m3, d, engine = "robust", goal = "prediction")
  q <- mr_fit(grain_yield_t_ha ~ N_rate_kg_ha + P_rate_kg_ha +
                soil_water_m3_m3, d, engine = "quantile", tau = .5,
              goal = "prediction")
  expect_true(is.finite(mr_validate(rob, v = 3, repeats = 1)$summary$mean[1]))
  expect_true(is.finite(mr_validate(q, v = 3, repeats = 1)$summary$mean[1]))
})

test_that("GAM engine is refitted safely across folds", {
  skip_if_not_installed("mgcv")
  d <- mr_example_data("irrigation_nonlinear")
  fit <- mr_fit(yield_t_ha ~ s(irrigation_mm) + s(N_rate_kg_ha) +
                  s(mean_temp_C), d, engine = "gam", goal = "prediction")
  z <- mr_validate(fit, v = 3, repeats = 1, seed = 7)
  expect_true(is.finite(z$summary$mean[z$summary$metric == "RMSE"]))
})

test_that("kernel engine fits and predicts", {
  skip_if_not_installed("np")
  d <- mr_example_data("irrigation_nonlinear")[1:80, ]
  fit <- mr_fit(yield_t_ha ~ irrigation_mm + N_rate_kg_ha,
                d, engine = "kernel", goal = "prediction")
  pr <- predict(fit, d[1:5, ])
  expect_length(pr, 5)
  expect_true(all(is.finite(pr)))
})

test_that("model comparison separates inference and prediction", {
  d <- mr_example_data("soil_fertility")
  a <- mr_fit(yield_t_ha ~ available_P_mg_dm3 + season_rain_mm,
              d, goal = "prediction")
  b <- mr_fit(yield_t_ha ~ organic_matter_pct + available_P_mg_dm3 +
                season_rain_mm, d, goal = "prediction")
  z <- mr_compare(a = a, b = b, v = 5, repeats = 1)
  expect_true(is.data.frame(z$inference))
  expect_true(is.data.frame(z$prediction))
  expect_true(all(c("model", "engine", "metric") %in% names(z$prediction)))
})
