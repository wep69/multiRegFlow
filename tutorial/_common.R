## ===========================================================================
## _common.R: infra-estrutura unica do tutorial auditado do multiRegFlow
## Tudo o que atravessa capitulos esta aqui. Nenhum numero e digitado na prosa.
## ===========================================================================

if (dir.exists("D:/RLibrary") && !("D:/RLibrary" %in% .libPaths()))
  .libPaths(c("D:/RLibrary", .libPaths()))

suppressPackageStartupMessages({
  library(multiRegFlow)
  library(ggplot2)
})

ART <- "_artefatos"
dir.create(ART, showWarnings = FALSE, recursive = TRUE)

PKG      <- "multiRegFlow"
PKG_VER  <- as.character(utils::packageVersion(PKG))
PKG_PATH <- find.package(PKG)
PKG_EXP  <- sort(getNamespaceExports(PKG))
PKG_S3   <- sort(grep("^(print|summary|plot|predict|coef)\\.",
                      ls(asNamespace(PKG), all.names = TRUE), value = TRUE))

`%||%` <- function(a, b) if (is.null(a)) b else a

## ---------------------------------------------------------------------------
## Formatacao em convencao brasileira, separador decimal por virgula
## ---------------------------------------------------------------------------
fmt <- function(x, d = 3) {
  x <- suppressWarnings(as.numeric(x))
  if (length(x) == 0L) return("NA")
  out <- formatC(round(x, d), format = "f", digits = d,
                 big.mark = "", decimal.mark = ",")
  out[is.na(x)] <- "NA"
  trimws(out)
}
pct <- function(x, d = 1) paste0(fmt(100 * as.numeric(x), d), "%")

fmtp <- function(p, d = 4) {
  p <- suppressWarnings(as.numeric(p))
  vapply(p, function(v) {
    if (is.na(v)) return("NA")
    if (v < 1e-4) return(sub("\\.", ",", format(v, scientific = TRUE, digits = 3)))
    fmt(v, d)
  }, character(1), USE.NAMES = FALSE)
}

## p-valor com a forma que a agronomia usa, mas sem mentir sobre o tamanho
fmt_p <- function(p) {
  p <- suppressWarnings(as.numeric(p))
  vapply(p, function(v) {
    if (is.na(v)) return("NA")
    if (v < 0.001) return(sub("\\.", ",", format(v, scientific = TRUE, digits = 2)))
    paste0("= ", fmt(v, 3))
  }, character(1), USE.NAMES = FALSE)
}

## razao grande demais para ser lida por extenso vira ordem de grandeza
ordens <- function(r, d = 1) fmt(log10(abs(as.numeric(r))), d)

## ---------------------------------------------------------------------------
## Tabela que funciona em HTML e em Typst
## ---------------------------------------------------------------------------
tab <- function(x, caption = NULL, digits = 3, ...) {
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  k <- knitr::kable(x, caption = caption, digits = digits, booktabs = TRUE,
                    row.names = FALSE, linesep = "",
                    format.args = list(decimal.mark = ",", big.mark = ""), ...)
  if (requireNamespace("kableExtra", quietly = TRUE) && knitr::is_html_output())
    k <- kableExtra::kable_styling(k, bootstrap_options = c("striped", "condensed"),
                                   full_width = FALSE)
  k
}

## ---------------------------------------------------------------------------
## Cache indexado pelo codigo do bloco e pelas dependencias declaradas
## ---------------------------------------------------------------------------
cache_rds <- function(chave, expr, deps = NULL) {
  assinatura <- paste(c(deparse(substitute(expr)),
                        if (!is.null(deps)) deparse(deps)), collapse = "\n")
  f <- file.path(ART, paste0("cache-", chave, ".rds"))
  if (file.exists(f)) {
    obj <- readRDS(f)
    if (is.list(obj) && identical(obj[[".assinatura"]], assinatura))
      return(obj[[".valor"]])
    message("cache '", chave, "' descartado: o codigo do bloco mudou")
  }
  val <- force(expr)
  saveRDS(list(.assinatura = assinatura, .valor = val), f)
  val
}

## ---------------------------------------------------------------------------
## Registro de uso: e ele que calcula a cobertura, em vez de afir-mar
## ---------------------------------------------------------------------------
## uso_chave e um arquivo por capitulo, com uma linha por chamada registrada.
## A cobertura do livro e o confronto entre este registro e formals(), feito
## no proprio render.
USO <- new.env(parent = emptyenv())
USO$registro <- list()
USO$decisoes <- list()

usar <- function(...) {
  args <- list(...)
  fn <- as.character(substitute(...))[[1]]
  nms <- names(args)
  ## funcao chamada sem nenhum argumento nomeado: registra a chamada como
  ## um argumento sentinela, para a linha ter largura um e o registro nao
  ## quebrar quando as colunas nao batem.
  if (is.null(nms) || length(nms) == 0L) {
    registro <- list(funcao = fn, argumentos = "(sem argumento nomeado)",
                     valores = "")
  } else {
    registro <- list(
      funcao = fn,
      argumentos = nms,
      valores  = vapply(args, function(a) paste(format(a), collapse = "|"),
                        character(1)))
  }
  USO$registro[[length(USO$registro) + 1L]] <- registro
  invisible(registro)
}

salvar_uso <- function(capitulo) {
  r <- USO$registro
  if (length(r) == 0L) {
    ## capitulo sem nenhuma chamada registrada: quadro vazio de largura certa
    df <- data.frame(capitulo = character(0), funcao = character(0),
                     argumento = character(0), valor = character(0),
                     stringsAsFactors = FALSE)
  } else {
    df <- do.call(rbind, lapply(r, function(x)
      data.frame(capitulo = capitulo,
                 funcao   = rep(x$funcao, length(x$argumentos)),
                 argumento = x$argumentos,
                 valor     = x$valores,
                 stringsAsFactors = FALSE)))
    rownames(df) <- NULL
  }
  f <- file.path(ART, paste0("uso-", capitulo, ".rds"))
  saveRDS(df, f)
  df
}

salvar_decisoes <- function(capitulo, decisao, evidencia) {
  d <- data.frame(capitulo = capitulo, decisao = decisao, evidencia = evidencia,
                  stringsAsFactors = FALSE)
  f <- file.path(ART, paste0("dec-", capitulo, ".rds"))
  saveRDS(d, f)
  assign(paste0("dec_", capitulo), d, envir = USO)
  d
}

## A cobertura e CALCULADA: confronto entre o registro e a assinatura real.
cobertura <- function() {
  f <- list.files(ART, pattern = "^uso-.*\\.rds$", full.names = TRUE)
  registro <- if (length(f) == 0L) {
    data.frame(funcao = character(0), argumento = character(0))
  } else {
    do.call(rbind, lapply(f, readRDS))
  }
  linhas <- lapply(PKG_EXP, function(fn) {
    fo <- formals(get(fn, envir = asNamespace(PKG)))
    argn <- names(fo)
    usados <- sort(unique(registro$argumento[registro$funcao == fn]))
    exercitados <- intersect(argn, usados)
    data.frame(funcao = fn, n_argumentos = length(argn),
               exercitados = length(exercitados),
               pct = if (length(argn) == 0L) NA_real_ else
                     100 * length(exercitados) / length(argn),
               faltando = paste(setdiff(argn, exercitados), collapse = ", "),
               stringsAsFactors = FALSE)
  })
  do.call(rbind, linhas)
}

## ---------------------------------------------------------------------------
## Preservacao do estado do gerador aleatorio em volta de chamada do pacote
## ---------------------------------------------------------------------------
preservando_semente <- function(expr) {
  tinha <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  antes <- if (tinha) get(".Random.seed", envir = .GlobalEnv) else NULL
  on.exit({
    if (tinha) assign(".Random.seed", antes, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  force(expr)
}

## o pacote aceita `seed` e a propaga, mas nao restaura o estado global
## depois da chamada. Todo bloco que sorteia passa por aqui.
sorteando <- function(expr) preservando_semente(expr)

## ---------------------------------------------------------------------------
## Tema das figuras, unico no livro inteiro
## ---------------------------------------------------------------------------
tema_pacote <- function(base = 11) {
  theme_minimal(base_size = base) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = "grey92", linewidth = 0.3),
      strip.text = element_text(face = "bold", colour = "grey20"),
      plot.title = element_text(face = "bold", size = base * 1.05),
      plot.subtitle = element_text(colour = "grey30", size = base * 0.9),
      plot.caption = element_text(colour = "grey45", size = base * 0.75, hjust = 0),
      legend.position = "bottom",
      axis.text = element_text(colour = "grey20")
    )
}

AZUL  <- "#2C5F8A"; VERDE <- "#3F7D3F"; LARANJA <- "#C1712B"
CINZA <- "#8C8C8C"; ROXO <- "#6B4C8A"; VERM <- "#A63A3A"

## ===========================================================================
## CENARIOS: dados simulados com discrepancia plantada por construcao
## Nenhum deles e dado de campo. Todos sao sinteticos, com semente fixa.
## ===========================================================================

## --- A: ensaio de fertilidade, heteroscedastico, com tres outliers ---------
## VERDADE A: a relacao e linear em todos os preditores, os coeficientes
## verdadeiros sao conhecidos, e a variancia do erro CRESCE com a argila.
## A discrepancia que a heteroscedasticidade cria e mascarada pelos outliers.
VERDADE_A <- c(intercept = 4.20, pH = -0.45, MO = 0.32, P = 0.018,
               K = 0.0045, umidade = 0.075, chuva = 0.0021)
LINHAS_OUTLIER_A <- c(23L, 88L, 151L)
DESVIO_OUTLIER_A <- c(3.4, -3.1, 2.9)

dados_A <- function(semente = 20260823L) {
  set.seed(semente)
  n <- 200L
  pH      <- round(rnorm(n, 6.2, 0.55), 2)
  MO      <- round(pmax(0.3, rnorm(n, 2.4, 1.0)), 2)
  argila  <- round(runif(n, 12, 48), 1)
  P       <- round(pmax(1, rnorm(n, 22, 9)), 1)
  K       <- round(pmax(10, rnorm(n, 115, 35)), 1)
  umidade <- round(runif(n, 12, 34), 1)
  chuva   <- round(pmax(200, rnorm(n, 600, 110)), 0)
  mu <- VERDADE_A[["intercept"]] + VERDADE_A[["pH"]] * pH +
    VERDADE_A[["MO"]] * MO + VERDADE_A[["P"]] * P +
    VERDADE_A[["K"]] * K + VERDADE_A[["umidade"]] * umidade +
    VERDADE_A[["chuva"]] * chuva
  ## DISCREPANCIA PLANTADA 1: variancia proportional a argila. O teste de
  ## Breusch-Pagan enxerga esta, MAS so quando os outliers nao estao presentes.
  sigma <- 0.20 + argila / 48 * 0.90
  d <- data.frame(yield_t_ha = round(mu + rnorm(n, 0, sigma), 3),
                  soil_pH = pH, organic_matter_pct = MO, clay_pct = argila,
                  available_P_mg_dm3 = P, exchangeable_K_mg_dm3 = K,
                  soil_moisture_pct = umidade, season_rain_mm = chuva)
  ## DISCREPANCIA PLANTADA 2: tres observacoes deslocadas, em linhas fixas,
  ## com sinais opostos. E o que mascara o sinal de variancia.
  d$yield_t_ha[LINHAS_OUTLIER_A] <- d$yield_t_ha[LINHAS_OUTLIER_A] + DESVIO_OUTLIER_A
  attr(d, "sigma") <- sigma
  attr(d, "mu") <- mu
  d
}

FORM_A <- yield_t_ha ~ soil_pH + organic_matter_pct + clay_pct +
  available_P_mg_dm3 + exchangeable_K_mg_dm3 + soil_moisture_pct + season_rain_mm

## --- B: textura do solo deliberadamente redundante ---------------------------
## clay_pct, CEC e sandy_pct sao a mesma informacao medida tres vezes.
## Serve para mostrar que VIF alto nao e defeito do ajuste, e informacao
## que o desenho do dado carrega.
dados_B <- function(semente = 20260824L) {
  set.seed(semente)
  n <- 150L
  base <- rnorm(n, 0, 1)
  argila   <- round(15 + 12 * base + rnorm(n, 0, 0.35), 1)
  cec      <- round(8 + 0.45 * argila + rnorm(n, 0, 0.30), 1)
  arenoso  <- round(70 - 1.1 * argila + rnorm(n, 0, 1.0), 1)
  pH       <- round(6.0 + 0.030 * arenoso + rnorm(n, 0, 0.35), 2)
  P        <- round(pmax(1, rnorm(n, 20, 7)), 1)
  K        <- round(pmax(10, rnorm(n, 110, 25)), 1)
  chuva    <- round(pmax(200, rnorm(n, 600, 100)), 0)
  mu <- 3.2 + 0.028 * argila + 0.22 * pH + 0.020 * P + 0.0035 * K + 0.0020 * chuva
  data.frame(yield_t_ha = round(mu + rnorm(n, 0, 0.45), 3),
             clay_pct = argila, CEC_cmolc_dm3 = cec, sandy_pct = arenoso,
             soil_pH = pH, available_P_mg_dm3 = P,
             exchangeable_K_mg_dm3 = K, season_rain_mm = chuva)
}

## --- C: a cresta, em que o otimo de irrigacao depende da dose de N ---------
## Nenhuma analise univariada de irrigacao ve isto: ela devolve o otimo MARGINAL,
## que e correto so para quem esta na dose media de N.
dados_C <- function(semente = 20260825L) {
  set.seed(semente)
  n <- 170L
  Ndose <- round(runif(n, 40, 160), 1)
  Irrig  <- round(runif(n, 100, 400), 1)
  Temp   <- round(rnorm(n, 26, 2.0), 1)
  I_opt  <- 80 + 1.20 * Ndose
  mu <- 12.0 - 0.00090 * (Irrig - I_opt)^2 - 0.00055 * (Ndose - 100)^2 +
    0.10 * (Temp - 26) - 0.0016 * (Temp - 26)^2
  d <- data.frame(yield_t_ha = round(mu + rnorm(n, 0, 0.40), 3),
                  N_rate_kg_ha = Ndose, irrigation_mm = Irrig, mean_temp_C = Temp)
  attr(d, "I_opt") <- I_opt
  d
}
I_OPT_MARGINAL <- function(d) 80 + 1.20 * mean(d$N_rate_kg_ha)

## --- D: duas unidades de parcela em posicao extrema de manejo -------------
dados_D <- function(semente = 20260826L) {
  set.seed(semente); n <- 200L
  Ndose <- round(runif(n, 40, 160), 1); Pdose <- round(runif(n, 20, 120), 1)
  K     <- round(runif(n, 40, 200), 1)
  agua  <- round(runif(n, 0.12, 0.38), 3)
  mu <- 2.4 + 0.040 * Ndose + 0.014 * Pdose + 0.0055 * K + 6.0 * agua
  d <- data.frame(grain_yield_t_ha = round(mu + rnorm(n, 0, 0.35), 3),
                  N_rate_kg_ha = Ndose, P_rate_kg_ha = Pdose,
                  exchangeable_K_mg_dm3 = K, soil_water_m3_m3 = agua)
  ## DISCREPANCIA PLANTADA: duas unidades com todas as variaveis de manejo no
  ## extremo superior e resposta DESLOCADA PARA BAIXO. E o caso em que a
  ## fitted passa longe da resposta e o residuo fica grande.
  idx <- c(41L, 158L)
  d$P_rate_kg_ha[idx]        <- c(119, 117)
  d$exchangeable_K_mg_dm3[idx] <- c(199, 196)
  d$soil_water_m3_m3[idx]    <- c(0.379, 0.376)
  d$N_rate_kg_ha[idx]        <- c(11, 13)
  d$grain_yield_t_ha[idx]    <- d$grain_yield_t_ha[idx] - 2.2
  attr(d, "idx_alavancamento") <- idx
  d
}
LINHAS_ALAVANCAMENTO_D <- c(41L, 158L)

## --- E: seis blocos, para a covarianca por agrupamento ----------------------
dados_E <- function(semente = 20260827L) {
  set.seed(semente)
  bloco <- factor(rep(1:6, each = 30))
  n <- length(bloco)
  Ndose <- round(runif(n, 40, 160), 1); Pdose <- round(runif(n, 20, 120), 1)
  K     <- round(runif(n, 40, 200), 1)
  base <- 2.4 + 0.040 * Ndose + 0.014 * Pdose + 0.0055 * K
  d <- data.frame(
    grain_yield_t_ha = round(base + rnorm(6, 0, 0.55)[as.integer(bloco)] +
                               rnorm(n, 0, 0.42), 3),
    N_rate_kg_ha = Ndose, P_rate_kg_ha = Pdose, exchangeable_K_mg_dm3 = K,
    bloco = bloco)
  attr(d, "efeito_bloco") <- c(-0.9, -0.2, 0.15, 0.6, 0.05, 0.85)
  d
}

## --- F: predicao com ruido alto ---------------------------------------------
## O sinal existe, mas o ruido manda. Serve para separar ajuste de previsao.
dados_F <- function(semente = 20260828L) {
  set.seed(semente); n <- 200L
  MO <- round(runif(n, 0.5, 4.0), 2); P <- round(pmax(1, rnorm(n, 21, 8)), 1)
  chuva <- round(pmax(200, rnorm(n, 600, 120)), 0)
  mu <- 3.0 + 0.30 * MO + 0.016 * P + 0.0022 * chuva
  d <- data.frame(yield_t_ha = round(mu + rnorm(n, 0, 1.05), 3),
                  organic_matter_pct = MO, available_P_mg_dm3 = P,
                  season_rain_mm = chuva)
  attr(d, "mu") <- mu
  d
}

## Tabela de cenarios, com o motivo de cada um existir. Entra no capitulo 1.
tabela_cenarios <- function() {
  data.frame(
    cenario = c("A", "B", "C", "D", "E", "F"),
    assunto = c("Fertilidade do solo, heteroscedastico, com outliers",
                "Textura redundante: mesma informacao medida tres vezes",
                "Crista: o otimo de irrigacao depende da dose de N",
                "Duas unidades de parcela em posicao extrema de manejo",
                "Seis blocos: covarianca agrupada e a unidade real de inferencia",
                "Sinal soterrado no ruido: ajuste bonito e previsao mediocre"),
    discrepancia = c("Variancia cresce com a argila; tres observacoes deslocadas",
                     "argila, CEC e areia com correlacao acima de 0,99",
                     "Otimo condicional invisivel a analise univariada",
                     "Alavancagem alta com resposta deslocada para baixo",
                     "Efeito de bloco com dispersao maior que a intraparenquial",
                     "Ruido de 1,05 para um sinal de amplitude 3,5"),
    exercita = c("toda a API no caminho completo",
                 "mr_collinearity, mr_select, mr_regularize",
                 "mr_fit com quatro motores, mr_quantile, mr_kernel",
                 "mr_influence e o motor robusto",
                 "mr_inference com vcov = cluster",
                 "mr_validate, mr_compare, mr_report"),
    stringsAsFactors = FALSE)
}
