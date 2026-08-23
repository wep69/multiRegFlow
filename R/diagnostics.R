#' Diagnose an OLS model
#'
#' Produces a compact audit of fit, rank, residual distribution,
#' heteroscedasticity, influence and a fitted-value-power specification screen.
#' The screens are intended to guide investigation; they are not automatic
#' accept/reject rules for a scientific model.
#'
#' @param x An `mr_fit` object fitted with `engine = "ols"`.
#' @return A list with fit, residual, heteroscedasticity, specification and
#'   influence summaries.
#' @export
mr_diagnose <- function(x) {
  .mr_assert_fit(x)
  if (x$engine != "ols") stop("mr_diagnose() currently targets OLS fits.", call. = FALSE)
  m <- x$model
  sm <- summary(m)
  r <- stats::residuals(m)
  h <- stats::hatvalues(m)
  cd <- stats::cooks.distance(m)
  shp <- if (length(r) >= 3L && length(r) <= 5000L) stats::shapiro.test(r) else NULL
  bp <- .mr_bp_test(m)
  reset <- .mr_reset_test(m)
  rank_def <- m$rank < length(stats::coef(m))
  p_eff <- m$rank - 1L
  n <- stats::nobs(m)
  list(
    goal = x$goal,
    fit = c(n = n, p = length(stats::coef(m)) - 1L,
            effective_rank = m$rank, residual_df = stats::df.residual(m),
            R2 = sm$r.squared, adjusted_R2 = sm$adj.r.squared,
            sigma = sm$sigma, AIC = stats::AIC(m), BIC = stats::BIC(m)),
    rank = c(rank_deficient = as.numeric(rank_def),
             n_to_effective_predictor_ratio = if (p_eff > 0) n / p_eff else Inf),
    residuals = c(mean = mean(r), sd = stats::sd(r),
                  shapiro_W = if (is.null(shp)) NA_real_ else unname(shp$statistic),
                  shapiro_p = if (is.null(shp)) NA_real_ else shp$p.value),
    heteroscedasticity = bp,
    specification = reset,
    influence = c(max_hat = max(h), max_cooks_distance = max(cd),
                  n_cook_gt_4_over_n = sum(cd > 4 / length(cd))),
    note = if (x$goal == "explanation") {
      paste("Interpret diagnostics jointly. Normality is mainly relevant to exact",
            "small-sample inference; heteroscedasticity can often be addressed",
            "with robust covariance or wild bootstrap without changing the mean model.")
    } else {
      paste("Diagnostics describe model adequacy, but predictive performance must",
            "be evaluated with observations not used to fit the model.")
    }
  )
}

#' Influence diagnostics
#'
#' Returns observation-level influence measures and transparent screening flags.
#' The flags identify observations for inspection or sensitivity analysis; they
#' are not instructions to delete observations.
#'
#' @param x An OLS `mr_fit` object.
#' @return A data frame with leverage, standardized/studentized residuals,
#'   Cook's distance, DFFITS, maximum absolute DFBETA and screening flags.
#' @export
mr_influence <- function(x) {
  .mr_assert_fit(x)
  if (x$engine != "ols") stop("mr_influence() currently targets OLS fits.", call. = FALSE)
  m <- x$model
  n <- stats::nobs(m)
  p <- m$rank
  db <- stats::dfbetas(m)
  leverage <- stats::hatvalues(m)
  cook <- stats::cooks.distance(m)
  dff <- stats::dffits(m)
  maxdb <- apply(abs(db), 1, max, na.rm = TRUE)
  lev_thr <- 2 * p / n
  cook_thr <- 4 / n
  dff_thr <- 2 * sqrt(p / n)
  db_thr <- 2 / sqrt(n)
  data.frame(
    row = seq_len(n),
    fitted = stats::fitted(m),
    residual = stats::residuals(m),
    rstandard = stats::rstandard(m),
    rstudent = stats::rstudent(m),
    leverage = leverage,
    cooks_distance = cook,
    dffits = dff,
    max_abs_dfbeta = maxdb,
    flag_leverage = leverage > lev_thr,
    flag_cook = cook > cook_thr,
    flag_dffits = abs(dff) > dff_thr,
    flag_dfbeta = maxdb > db_thr,
    row.names = NULL
  )
}

#' Multicollinearity diagnostics
#'
#' Returns VIF/tolerance, condition indices, variance-decomposition proportions
#' and the strongest pairwise correlations among model-matrix columns. If
#' package `performance` is installed, its VIF/GVIF table with confidence
#' intervals is also returned for supported specifications.
#'
#' @param x An OLS `mr_fit` object.
#' @return A list of collinearity diagnostics.
#' @export
mr_collinearity <- function(x) {
  .mr_assert_fit(x)
  if (x$engine != "ols") stop("mr_collinearity() currently targets OLS fits.", call. = FALSE)
  xy <- .mr_xy(x)
  X <- xy$X
  vif <- .mr_vif_numeric(as.data.frame(X))
  cond <- .mr_condition(X)
  perf <- NULL
  if (requireNamespace("performance", quietly = TRUE)) {
    perf <- tryCatch(performance::check_collinearity(x$model), error = function(e) NULL)
  }
  ci_tbl <- data.frame(
    dimension = names(cond$condition_index),
    condition_index = unname(cond$condition_index),
    flag_ci15 = unname(cond$condition_index) >= 15,
    flag_ci30 = unname(cond$condition_index) >= 30,
    row.names = NULL
  )
  list(
    VIF = vif,
    condition_index = ci_tbl,
    variance_decomposition = cond$variance_decomposition,
    correlations = .mr_cor_pairs(as.data.frame(X)),
    performance = perf,
    interpretation = paste(
      "VIF, condition indices, variance-decomposition proportions and the",
      "scientific role of correlated predictors should be interpreted together.",
      "A variable is never removed automatically because a threshold is exceeded."
    )
  )
}
