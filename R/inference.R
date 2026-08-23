#' Coefficient inference with classical or robust covariance estimators
#'
#' Computes coefficient tables using the classical OLS covariance matrix,
#' heteroscedasticity-consistent HC0-HC5 estimators, or a cluster-robust
#' covariance matrix. Cluster-robust inference uses G-1 reference degrees of
#' freedom, where G is the number of observed clusters.
#'
#' @param x An OLS `mr_fit` object.
#' @param vcov Covariance estimator: "classical", "HC0", "HC1", "HC2",
#'   "HC3", "HC4", "HC4m", "HC5", or "cluster".
#' @param cluster Optional vector, column name in `x$data`, or one-sided formula
#'   identifying clusters when `vcov = "cluster"`.
#' @param conf Confidence level.
#' @return A data frame with estimates, standard errors, test statistics,
#'   degrees of freedom, p-values, and confidence limits.
#' @export
mr_inference <- function(x,
                         vcov = c("classical", "HC3", "HC0", "HC1", "HC2",
                                  "HC4", "HC4m", "HC5", "cluster"),
                         cluster = NULL, conf = 0.95) {
  .mr_assert_fit(x)
  if (x$engine != "ols") stop("mr_inference() currently targets OLS fits.", call. = FALSE)
  vcov <- match.arg(vcov)
  if (conf <= 0 || conf >= 1) stop("`conf` must be between 0 and 1.", call. = FALSE)
  m <- x$model
  beta <- stats::coef(m)

  if (vcov == "classical") {
    V <- stats::vcov(m)
    df <- stats::df.residual(m)
    clusters <- NA_integer_
  } else {
    .mr_require("sandwich", "for robust covariance estimation")
    if (vcov == "cluster") {
      if (is.null(cluster)) stop("Supply `cluster` when vcov = 'cluster'.", call. = FALSE)
      cl <- cluster
      if (is.character(cluster) && length(cluster) == 1L) {
        if (!cluster %in% names(x$data)) stop("The cluster column was not found in `x$data`.", call. = FALSE)
        cl <- x$data[[cluster]]
      } else if (inherits(cluster, "formula")) {
        cl <- stats::model.frame(cluster, data = x$data)[[1L]]
      }
      mf <- .mr_model_frame(x)
      if (length(cl) != nrow(x$data)) {
        stop("`cluster` must have one value per row in the original data.", call. = FALSE)
      }
      used <- suppressWarnings(as.integer(rownames(mf)))
      if (length(used) != nrow(mf) || anyNA(used)) used <- seq_len(nrow(mf))
      cl_used <- cl[used]
      clusters <- length(unique(cl_used))
      if (clusters < 2L) stop("At least two clusters are required.", call. = FALSE)
      V <- sandwich::vcovCL(m, cluster = cl_used, type = "HC1")
      df <- max(clusters - 1L, 1L)
    } else {
      V <- sandwich::vcovHC(m, type = vcov)
      df <- stats::df.residual(m)
      clusters <- NA_integer_
    }
  }

  se <- sqrt(diag(V))
  stat <- beta / se
  p <- 2 * stats::pt(abs(stat), df = df, lower.tail = FALSE)
  alpha <- 1 - conf
  crit <- stats::qt(1 - alpha / 2, df = df)

  data.frame(
    term = names(beta), estimate = unname(beta), std_error = unname(se),
    statistic = unname(stat), df = df, p_value = unname(p),
    conf_low = unname(beta - crit * se), conf_high = unname(beta + crit * se),
    covariance = vcov, clusters = clusters, row.names = NULL
  )
}
