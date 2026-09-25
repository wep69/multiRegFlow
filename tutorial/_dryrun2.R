## _dryrun2.R: ensaio seco. Avalia expressao por expressao de nivel superior,
## para dizer exatamente qual bloco parou, e cronometra o total.
setwd("D:/Walter/R/Pacotes_criados/Tutoriais/multiRegFlow/livro")
if (dir.exists("D:/RLibrary") && !("D:/RLibrary" %in% .libPaths()))
  .libPaths(c("D:/RLibrary", .libPaths()))

arqs <- commandArgs(trailingOnly = TRUE)
if (!length(arqs)) arqs <- list.files(".", pattern = "^(index|[0-9]).*\\.qmd$")
arqs <- sort(arqs[file.exists(arqs)])

cat("capitulos a testar:", length(arqs), "\n\n")

for (a in arqs) {
  tmp <- tempfile(fileext = ".R")
  ok <- tryCatch({
    knitr::purl(a, output = tmp, quiet = TRUE, documentation = 0); TRUE
  }, error = function(e) {
    cat(">>> ", a, ": FALHA NO PURL: ", conditionMessage(e), "\n", sep = ""); FALSE })
  if (!ok) next

  exps <- tryCatch(parse(tmp, encoding = "UTF-8"),
                   error = function(e) {
                     cat(">>> ", a, ": FALHA NO PARSE: ", conditionMessage(e), "\n", sep = "")
                     NULL })
  if (is.null(exps)) next

  e <- new.env(parent = globalenv())
  parou <- FALSE
  t0 <- system.time({
    for (i in seq_along(exps)) {
      r <- tryCatch({
        suppressWarnings(suppressMessages(eval(exps[[i]], envir = e)))
        NULL
      }, error = function(x) conditionMessage(x))
      if (!is.null(r)) {
        cat(">>> ", a, ": ERRO na expressao ", i, " de ", length(exps), "\n", sep = "")
        cat("    codigo : ", substr(paste(deparse(exps[[i]]), collapse = " "), 1, 300), "\n", sep = "")
        cat("    erro   : ", r, "\n", sep = "")
        parou <- TRUE
        break
      }
    }
  })[["elapsed"]]
  if (!parou) cat(">>> ", a, ": OK em ", round(t0, 1), " s (", length(exps), " expressoes)\n", sep = "")
}
