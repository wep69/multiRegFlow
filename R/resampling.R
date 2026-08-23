#' Bootstrap OLS coefficients
#'
#' Supports pairs, residual and wild bootstrap. Wild bootstrap uses Rademacher
#' multipliers and is useful as a sensitivity analysis under heteroscedasticity.
#'
#' @param x An OLS `mr_fit` object.
#' @param R Number of bootstrap replicates.
#' @param type "pairs", "residual", or "wild".
#' @param seed Random seed.
#' @param conf Confidence level.
#' @param interval Bootstrap interval: "percentile", "basic", or "normal".
#' @return A list with bootstrap draws, intervals, sign stability and the number
#'   of successful replicates.
#' @export
mr_bootstrap <- function(x, R = 999, type = c("pairs", "residual", "wild"),
                         seed = 123, conf = 0.95,
                         interval = c("percentile", "basic", "normal")) {
  .mr_assert_fit(x)
  if (x$engine != "ols") stop("mr_bootstrap() currently targets OLS fits.", call. = FALSE)
  type <- match.arg(type)
  interval <- match.arg(interval)
  if (R < 20L) warning("Very small `R`; use a larger number for final inference.", call. = FALSE)
  if (conf <= 0 || conf >= 1) stop("`conf` must be between 0 and 1.", call. = FALSE)
  mf <- .mr_model_frame(x)
  n <- nrow(mf)
  beta0 <- stats::coef(x$model)
  draws <- matrix(NA_real_, R, length(beta0), dimnames = list(NULL, names(beta0)))
  set.seed(seed)
  fitted0 <- stats::fitted(x$model)
  resid0 <- stats::residuals(x$model)
  response <- x$response
  for (b in seq_len(R)) {
    d <- mf
    if (type == "pairs") {
      idx <- sample.int(n, n, replace = TRUE)
      d <- mf[idx, , drop = FALSE]
    } else if (type == "residual") {
      d[[response]] <- fitted0 + sample(resid0, n, replace = TRUE)
    } else {
      mult <- sample(c(-1, 1), n, replace = TRUE)
      d[[response]] <- fitted0 + resid0 * mult
    }
    fb <- tryCatch(stats::lm(x$formula, data = d), error = function(e) NULL)
    if (!is.null(fb)) {
      z <- stats::coef(fb)
      draws[b, names(z)] <- z
    }
  }
  alpha <- (1 - conf) / 2
  qs <- t(apply(draws, 2, stats::quantile,
                probs = c(alpha, 0.5, 1 - alpha), na.rm = TRUE))
  if (interval == "percentile") {
    ints <- qs
  } else if (interval == "basic") {
    ints <- cbind(
      lower = 2 * beta0 - qs[, 3],
      median = qs[, 2],
      upper = 2 * beta0 - qs[, 1]
    )
  } else {
    z <- stats::qnorm(1 - alpha)
    mu <- colMeans(draws, na.rm = TRUE)
    se <- apply(draws, 2, stats::sd, na.rm = TRUE)
    ints <- cbind(lower = mu - z * se, median = mu, upper = mu + z * se)
  }
  colnames(ints) <- c("lower", "median", "upper")
  okrep <- rowSums(is.finite(draws)) > 0
  sign_ref <- matrix(sign(beta0), R, length(beta0), byrow = TRUE)
  list(
    type = type, interval = interval, R = R,
    successful_replicates = sum(okrep),
    coefficients = draws, original = beta0, intervals = ints,
    sign_stability = colMeans(sign(draws) == sign_ref, na.rm = TRUE)
  )
}

#' Repeated cross-validation
#'
#' Evaluates predictive performance with genuinely out-of-fold predictions.
#' OLS, robust regression, GAM and kernel regression are supported. Quantile
#' regression is supported when the fitted object contains a single quantile.
#'
#' @param x An `mr_fit` object.
#' @param v Number of folds.
#' @param repeats Number of repetitions.
#' @param seed Random seed.
#' @return Metrics by repeat plus all out-of-fold predictions. Metrics include
#'   RMSE, MAE, out-of-fold R-squared, calibration intercept and calibration slope.
#' @export
mr_validate <- function(x, v = 10, repeats = 5, seed = 123) {
  .mr_assert_fit(x)
  if (x$engine == "quantile" && length(x$tau) != 1L) {
    stop("Cross-validation of quantile fits requires a single `tau`.", call. = FALSE)
  }
  mf <- .mr_model_frame(x)
  n <- nrow(mf)
  if (v < 2L || v > n) stop("`v` must be between 2 and the number of complete observations.", call. = FALSE)
  if (repeats < 1L) stop("`repeats` must be at least 1.", call. = FALSE)
  metric_names <- c("RMSE", "MAE", "R2", "calibration_intercept", "calibration_slope")
  all <- vector("list", repeats)
  met <- matrix(NA_real_, repeats, length(metric_names),
                dimnames = list(NULL, metric_names))
  for (r in seq_len(repeats)) {
    fold <- .mr_fold_id(n, v, seed + r - 1L)
    pred <- rep(NA_real_, n)
    for (k in seq_len(v)) {
      tr <- mf[fold != k, , drop = FALSE]
      te <- mf[fold == k, , drop = FALSE]
      fit <- .mr_refit(x, tr)
      pk <- predict(fit, newdata = te)
      if (is.matrix(pk)) {
        if (ncol(pk) != 1L) stop("Validation produced multi-column predictions.", call. = FALSE)
        pk <- pk[, 1]
      }
      pred[fold == k] <- as.numeric(pk)
    }
    obs <- mf[[x$response]]
    met[r, ] <- .mr_metrics(obs, pred)
    all[[r]] <- data.frame(repeat_id = r, row = seq_len(n), observed = obs,
                           predicted = pred, fold = fold)
  }
  list(
    engine = x$engine,
    metrics = as.data.frame(met),
    summary = data.frame(metric = colnames(met),
                         mean = colMeans(met, na.rm = TRUE),
                         sd = apply(met, 2, stats::sd, na.rm = TRUE),
                         row.names = NULL),
    predictions = do.call(rbind, all)
  )
}
