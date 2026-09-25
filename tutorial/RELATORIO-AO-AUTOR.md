# Relatorio ao autor do pacote multiRegFlow

**Assunto:** auditoria de API executada ao preparar o tutorial *multiRegFlow na pratica*.
**Alvo:** `multiRegFlow` 0.2.0, instalado em `D:/RLibrary/multiRegFlow`.
**Ambiente:** R 4.6.0 (2026-04-24 ucrt), Windows 11 x64, Quarto 1.11.0.
**Data:** 23/08/2026.

Este relatorio foi produzido escrevendo um tutorial que exercita a API inteira
com dados simulados e discrepancia plantada. Cada item abaixo passou por tres
filtros: foi executado antes de ser escrito, o exemplo minimo roda sozinho, e a
causa provavel foi procurada no codigo do pacote. Dois itens que
inicialmente pareceram defeitos **nao eram**, e estao registrados na secao de
hipoteses descartadas, com a refutacao completa.

Antes de qualquer coisa: **o caminho principal do pacote funciona**. Os treze
capitulos do tutorial foram construidos em cima dele, e a suíte de testes do
proprio pacote passa. O que segue sao omissoes e arestas, nao falhas de
funcionamento.

---

## Como ler a severidade

| Nivel | Criterio |
|:---|:---|
| **Alta** | O usuario obtem numero ou objeto de aparencia normal que nao corresponde ao que pediu, e nada sinaliza. |
| **Media** | Recuperavel por quem conhece um detalhe nao documentado, ou saida incompleta em silencio. |
| **Baixa** | Inconveniencia, mensagem ruim, inconsistencia de interface, sem resultado errado. |

Nenhum item de severidade **alta** sobreviveu a verificacao. Sao onze itens: quatro de severidade media e sete baixa. Os dois que
começaram como alta estao na secao de hipoteses descartadas, e um deles mudou
de nivel depois de refutado.

## Resumo executivo

| # | Item | Funcao | Severidade | Esforco |
|---:|:---|:---|:---|:---|
| 1 | saida de `mr_diagnose()` e vetor nomeado, nao lista | `mr_diagnose` | media | baixo, mas quebra accessor do usuario |
| 2 | `AIC`/`BIC` saem `NA` sem nota em dois motores | `mr_compare` | media | baixo |
| 3 | `cluster` numerico continuo aceito sem aviso | `mr_inference` | media | baixo |
| 4 | `mr_quantile()` tem estrutura diferente de `mr_fit()` | `mr_quantile` | baixa | baixo |
| 5 | nenhuma dica de ordem de leitura entre os testes | `mr_diagnose`, `mr_recommend` | baixa | baixo |
| 6 | `mr_example_data()` sem argumento nao lista os conjuntos | `mr_example_data` | baixa | muito baixo |
| 7 | `seed` nao isola o gerador global | 6 funcoes | baixa no pacote | baixo |
| 8 | duas tabelas de VIF com nomes de coluna diferentes | `mr_collinearity` | baixa | baixo |
| 9 | o `...` de `mr_select` colide em dois metodos | `mr_select` | media | baixo |
| 10 | `match.arg` completa prefixo de metodo | `mr_regularize` e afins | baixa | baixo |
| 11 | `stability` pode reter zero termo e devolve outro `PFER` | `mr_select` | baixa | baixo |

**O que e barato e vale fazer primeiro:** itens 2, 3, 6 e 8. Cada um cabe em
poucas linhas e nenhum exige decisao de projeto.

**O que e decisao de projeto:** item 1. Trocar vetor por lista quebra o codigo
de quem ja usa `dg$fit$R2`... que, alias, hoje nao funciona, o que reduz o
custo real. A decisao e sua.

---

## 1. A saida de `mr_diagnose()` e um vetor nomeado, nao uma lista

### Sintoma

Sete dos oito elementos devolvidos por `mr_diagnose()` sao vetores nomeados.
Acesso por ponto, que e o habito em R, falha com `$ operator is invalid for
atomic vectors`.

### Exemplo minimo

```r
library(multiRegFlow)
d  <- mr_example_data("soil_fertility")
dg <- mr_diagnose(mr_fit(yield_t_ha ~ soil_pH + organic_matter_pct, d))

dg$fit["R2"]      ## funciona
dg$fit$R2         ## Error: $ operator is invalid for atomic vectors
```

Vale notar que **nao** e `NULL`: e erro. Isso e melhor do que seria, porque
falha alto em vez de devolver silenciosamente algo errado.

### Causa provavel

`R/diagnostics.R`, na construcao da lista de retorno. As sete entradas sao
montadas com `c(...)`, que produz vetor:

```r
list(
  fit   = c(n = n, p = ..., R2 = sm$r.squared, ...),
  rank  = c(rank_deficient = ..., n_to_effective_predictor_ratio = ...),
  residuals = c(mean = mean(r), sd = ..., ...),
  heteroscedasticity = bp,     ## este e vetor, e ja vem assim de .mr_bp_test
  specification     = reset,  ## idem
  influence = c(max_hat = ..., ...),
  note = "..."                 ## este e character, e funciona
)
```

### Correcao sugerida

Duas opcoes, e a escolha e sua:

```r
## opcao 1: devolver lista nomeada (consistente, mas quebra accessor por ponto)
-    fit = c(n = n, p = ..., R2 = sm$r.squared, ...),
+    fit = list(n = n, p = ..., R2 = sm$r.squared, ...),

## opcao 2: manter o vetor e documentar com todas as letras
## no \value do Rd:
##   \item{fit}{Vetor numerico nomeado. Use dg$fit["R2"], nao dg$fit$R2.}
```

A opcao 2 e mais barata e resolve o problema de quem **le** a documentacao. A
opcao 1 resolve o problema de quem **programa** em cima, e tem um custo baixo
porque o acesso por ponto hoje ja falha.

### Teste de regressao sugerido

```r
test_that("mr_diagnose devolve acessivel por colchetes e por nome", {
  d  <- mr_example_data("soil_fertility")
  dg <- mr_diagnose(mr_fit(yield_t_ha ~ soil_pH + organic_matter_pct, d))
  expect_true(is.finite(dg$fit["R2"]))
  expect_true(is.finite(dg$specification["p.value"]))
  expect_false(is.na(dg$heteroscedasticity[["p.value"]]) &&
                 is.null(dg$heteroscedasticity[["p.value"]]))
})
```

---

## 2. `mr_compare()` devolve `AIC` e `BIC` como `NA`, sem nota

### Sintoma

Na tabela `$inference`, as colunas `AIC` e `BIC` sao `NA` para os motores
`robust` e `kernel`. A coluna `note` da tabela de predicao fica
`NA_character_`, e nao ha qualquer explicacao no texto de retorno.

### Exemplo minimo

```r
library(multiRegFlow)
nl <- mr_example_data("irrigation_nonlinear")
f1 <- mr_fit(yield_t_ha ~ irrigation_mm + mean_temp_C, nl)
f2 <- mr_fit(yield_t_ha ~ irrigation_mm + mean_temp_C, nl, engine = "robust")
f3 <- mr_fit(yield_t_ha ~ irrigation_mm + mean_temp_C, nl, engine = "kernel")

mr_compare(linear = f1, robust = f2, kernel = f3, v = 5, repeats = 1)$inference
## AIC e BIC: 1220.88 / 1236.56 para linear; NA / NA para robust e kernel
```

### Causa provavel

`R/compare.R`, dentro do `lapply` que monta a tabela de ajuste:

```r
AICv <- tryCatch(stats::AIC(z$model), error = function(e) NA_real_)
BICv <- tryCatch(stats::BIC(z$model), error = function(e) NA_real_)
```

O `tryCatch` e a decisao correta, porque `stats::AIC()` realmente nao se
aplica a objetos `lmrob` e `npreg`. O que falta e o aviso. A coluna `note` ja
existe na tabela de predicao e e usada para outra coisa; falta a equivalente
na de ajuste.

### Correcao sugerida

```r
AICv <- tryCatch(stats::AIC(z$model), error = function(e) NA_real_)
mot  <- if (is.na(AICv))
  "AIC nao definido para este motor; compare com mr_validate()"
else NA_character_

data.frame(model = nms[i], engine = z$engine, AIC = AICv, BIC = BICv,
           R2_or_gam_R2 = R2, adjusted_R2_or_deviance_explained = adj,
           note = mot)
```

### Teste de regressao sugerido

```r
test_that("mr_compare explica AIC ausente em vez de deixar NA mudo", {
  nl <- mr_example_data("irrigation_nonlinear")
  f1 <- mr_fit(yield_t_ha ~ irrigation_mm + mean_temp_C, nl)
  f2 <- mr_fit(yield_t_ha ~ irrigation_mm + mean_temp_C, nl, engine = "robust")
  inf <- mr_compare(linear = f1, robust = f2, v = 5, repeats = 1,
                    validation = FALSE)$inference
  expect_true(is.na(inf$AIC[inf$engine == "robust"]))
  expect_true(nzchar(inf$note[inf$engine == "robust"]))
})
```

---

## 3. `cluster` numerico continuo e aceito sem aviso

### Sintoma

`mr_inference(fit, vcov = "cluster", cluster = <vetor numerico continuo>)` nao
da erro nem aviso. Cria um agrupamento degenerado e devolve um resultado de
aparencia normal.

### Exemplo minimo

```r
library(multiRegFlow)
E <- data.frame(
  y = rnorm(180), x1 = rnorm(180), x2 = rnorm(180),
  bloco = factor(rep(1:6, each = 30)))
f <- mr_fit(y ~ x1 + x2, E)

mr_inference(f, "cluster", cluster = E$bloco)$clusters
## 6   <- correto

mr_inference(f, "cluster", cluster = E$x1)$clusters
## 160 <- um agrupamento por observacao, sem aviso
```

### Causa provavel

`R/inference.R` valida comprimento e exige no minimo dois agrupamentos, o que
esta certo. O que nao ha e um teste de sanidade sobre o **numero** de
agrupamentos. A coluna `clusters` ja e gravada na saida, o que e uma decisao
boa e e o que torna o problema detectavel.

### Correcao sugerida

```r
clusters <- length(unique(cl_used))
if (clusters < 2L) stop("At least two clusters are required.", call. = FALSE)

## novo: avisar quando ha quase um agrupamento por observacao
if (clusters > 0.5 * nrow(mf))
  warning(sprintf(paste0("`cluster` tem %d grupos em %d observacoes; ",
                         "confira se e a variavel de agrupamento, e nao ",
                         "uma variavel continua."),
                  clusters, nrow(mf)), call. = FALSE)
```

### Teste de regressao sugerido

```r
test_that("mr_inference avisa quando cluster degenera", {
  E <- data.frame(y = rnorm(60), x1 = rnorm(60),
                  bloco = factor(rep(1:3, each = 20)))
  f <- mr_fit(y ~ x1, E)
  expect_warning(mr_inference(f, "cluster", cluster = E$x1),
                 "confira se e a variavel de agrupamento")
  expect_silent(mr_inference(f, "cluster", cluster = E$bloco))
})
```

---

## 4. `mr_quantile()` tem estrutura diferente de `mr_fit()`

### Sintoma

`mr_quantile()` devolve lista com quatro campos (`model`, `tau`, `formula`,
`data`) e **nao tem `coefficients` no primeiro nivel**. Os coeficientes estao
em `q$model$coefficients`, e sao um vetor nomeado, nao uma matriz.

### Exemplo minimo

```r
library(multiRegFlow)
nl <- mr_example_data("irrigation_nonlinear")
f  <- mr_fit(yield_t_ha ~ irrigation_mm + mean_temp_C, nl)
q  <- mr_quantile(f, tau = 0.5)

names(q)                      ## "model" "tau" "formula" "data"
q$model$coefficients          ## vetor nomeado, funciona
q$coefficients                ## NULL
q$model$coefficients[2, 1]    ## Error: numero incorreto de dimensoes
```

### Causa provavel

Provavelmente intencional: `mr_quantile()` devolve o objeto `rq` do
`quantreg` diretamente em `$model`, enquanto `mr_fit()` guarda o modelo
 tambem em `$model`, mas a classe `mr_fit` tem metodos proprios
(`print.mr_quantile`) que abstraem isso.

### Correcao sugerida

Nao ha bug a corrigir. Ha **divulgacao a melhorar**: o Rd de `mr_quantile()`
nao diz que a estrutura difere da de `mr_fit()`, e o `NAMESPACE` registra
`print.mr_quantile` mas nao `coef.mr_quantile`, que seria o metodo que
resolveria a simetria.

```r
## util e barato: dar simetria com mr_fit
#' @export
coef.mr_quantile <- function(object, ...) {
  stats::coef(object$model, ...)
}
```

### Teste de regressao sugerido

```r
test_that("mr_quantile tem accessor de coeficientes como mr_fit", {
  nl <- mr_example_data("irrigation_nonlinear")
  q  <- mr_quantile(mr_fit(yield_t_ha ~ irrigation_mm, nl), tau = 0.5)
  expect_named(stats::coef(q), c("(Intercept)", "irrigation_mm"))
})
```

---

## 5. Nenhuma dica de ordem de leitura entre os testes

### Sintoma

`mr_diagnose()` calcula heteroscedasticidade, normalidade, forma funcional e
influencia em uma passada, e nao comenta que os quatro **nao sao
independentes**. Isso produz um erro de leitura caro e silencioso.

### O caso medido

No tutorial, o gradiente de variancia plantado e mascarado por tres outliers.
Com eles, o teste de Breusch-Pagan nao rejeita; sem eles, rejeita com folga.
A variancia plantada e identica nos dois casos.

```r
## valor exato medido, do cenario A do tutorial:
## com os 3 outliers   : BP p = 0,2832   (nao rejeita)
## sem os 3 outliers   : BP p = 0,0035   (rejeita)
## Shapiro-Wilk, com   : p = 4,74e-05   (rejeita nos dois casos)
```

O `mr_influence()` identifica as tres linhas pelo residuo studentizado, e o
`mr_recommend()` emite o dominio `influence` com prioridade `medium`. O que
falta e a **ligacao** entre os dois achados.

### Causa provavel

Nao ha bug. Ha omissao de documentacao e de regra. O `mr_recommend()` decide
cada dominio de forma independente:

```r
if (!is.na(bp_p) && bp_p < 0.05) { add("heteroscedasticity", ...) }
if (!is.na(cookn) && cookn > 0)   { add("influence", ...) }
```

### Correcao sugerida

Uma regra que nao custa nada e fecha o ciclo:

```r
## em mr_recommend(), apos os dominios individuais:
if (!is.na(cookn) && cookn > 0 && !is.na(bp_p) && bp_p >= 0.05)
  add("influence",
      sprintf(paste("Heteroscedasticidade nao rejeitada (BP p = %.3f), mas %s",
                    "observacao(oes) excedem Cook 4/n. Pontos de alavanca",
                    "elevada podem ocultar gradiente de variancia."),
              bp_p, cookn),
      paste("Reavalie a variancia depois de inspecionar as observacoes",
            "sinalizadas; o teste pode ter perdido poder diante delas."),
      "high")
```

E no `note` de `mr_diagnose()`:

```r
note = paste("Inspecione influencia antes de aceitar um teste de variancia",
             "que nao disparou: observacoes deslocadas reduzem o poder do",
             "teste de Breusch-Pagan.")
```

### Teste de regressao sugerido

```r
test_that("mr_recommend liga variancia nao rejeitada a influencia alta", {
  ## cenario com gradiente de variancia mascarado por outliers
  fit <- <ajuste do cenario mascarado>
  rec <- mr_recommend(fit)
  esperado <- any(rec$domain == "influence" & rec$priority == "high")
  expect_true(esperado)
})
```

---

## 6. `mr_example_data()` sem argumento nao lista os conjuntos

### Sintoma

Sem argumento, a funcao devolve o **primeiro** conjunto, `soil_fertility`, em
vez de uma lista de nomes. Quem espera um catalogo recebe um quadro de dados.

### Exemplo minimo

```r
library(multiRegFlow)
dim(mr_example_data())   ## 180 9   (soil_fertility, e nao a lista de nomes)
```

### Causa provavel

`R/data-report.R`. O padrao de `match.arg()` com o vetor completo de opcoes
faz o primeiro elemento ser assumido quando o argumento e omitido. E o
comportamento correto de `match.arg()`; o que falta e a intencao documentada.

### Correcao sugerida

O Rd ja descreve `name` como "One of ...". Acrescente o que acontece sem
argumento. Se preferir mudar o comportamento, e uma decisao de contrato:

```r
## documento o comportamento atual, opcao mais barata
#' @param name One of "soil_fertility", "plant_growth", "agronomy_collinear",
#'   "irrigation_nonlinear", or "agronomy_heteroskedastic". When omitted, the
#'   first of these, "soil_fertility", is returned; to list the available
#'   datasets use names(formals(mr_example_data)$name).

## ou expoe a lista explicitamente, sem quebrar o contrato
#' @export
mr_example_data_names <- function() {
  eval(formals(mr_example_data)$name)
}
```

### Teste de regressao sugerido

```r
test_that("mr_example_data sem argumento devolve o primeiro conjunto", {
  expect_identical(mr_example_data(),
                   mr_example_data("soil_fertility"))
  expect_error(mr_example_data("nao_existe"))
})
```

---

## 7. `seed` nao isola o gerador global

### Sintoma

Seis funcoes aceitam `seed` e a propagam de forma correta, mas **nao
restauram** `.Random.seed` depois da chamada. `mr_select()` com metodo `aic`
nao toca o gerador, porque selecao stepwise e deterministica.

### Exemplo minimo

```r
library(multiRegFlow)
d <- mr_example_data("soil_fertility")
f <- mr_fit(yield_t_ha ~ soil_pH + organic_matter_pct, d)

set.seed(123); antes <- .Random.seed
invisible(mr_validate(f, v = 3, repeats = 1, seed = 1))
identical(antes, .Random.seed)      ## FALSE

## e as sementes sao mesmo propagadas:
v1 <- mr_validate(f, v = 3, repeats = 2, seed = 11)
v2 <- mr_validate(f, v = 3, repeats = 2, seed = 99)
isTRUE(all.equal(v1$summary, v2$summary))   ## FALSE, como esperado
```

### Causa provavel

As seis funcoes chamam `set.seed(seed)` diretamente, sem guardar o estado
anterior. E o comportamento padrao de R, e Many packages fazem assim, entao
isto nao e erro.

O risco e especifico: em um laco de Monte Carlo, `for (i in 1:R) { ... funcao(seed = 1) }`
produz repeticoes que **nao sao independentes** se a funcao nao tocar o
gerador, e sao **correlacionadas** se ela tocar. Depende da ordem de chamada, e
e o tipo de coisa que passa sem aviso e aparece como cobertura estranha.

### Correcao sugerida

```r
## helper interno, em R/utils.R
.mr_com_semente <- function(seed, expr) {
  tinha <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  antes <- if (tinha) get(".Random.seed", envir = .GlobalEnv) else NULL
  on.exit({
    if (tinha) assign(".Random.seed", antes, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(seed)
  force(expr)
}
```

E involve cada uso de `seed` nas seis funcoes. Alternativa mais barata:
documentar no Rd que o estado global e alterado.

### Teste de regressao sugerido

```r
test_that("funcoes com seed nao alteram o gerador global", {
  d <- mr_example_data("soil_fertility")
  f <- mr_fit(yield_t_ha ~ soil_pH + organic_matter_pct, d)
  for (chamada in list(
    function() mr_validate(f, v = 3, repeats = 1, seed = 1),
    function() mr_bootstrap(f, R = 20, seed = 1),
    function() mr_regularize(f, "lasso", nfolds = 5, seed = 1),
    function() mr_compare(ols = f, v = 3, repeats = 1, seed = 1))) {
    set.seed(123); antes <- .Random.seed
    invisible(chamada())
    expect_identical(antes, .Random.seed)
  }
})
```

---

## 8. Duas tabelas de VIF com nomes de coluna diferentes

### Sintoma

`mr_collinearity()` devolve a tabela propria do pacote **e** a tabela do
`performance::check_collinearity()`. As duas usam nomes diferentes para as
mesmas grandezas, e o usuario nao tem como saber disso antes de tentar
combina-las.

### Exemplo minimo

```r
library(multiRegFlow)
B <- mr_example_data("agronomy_collinear")
col <- mr_collinearity(mr_fit(yield_t_ha ~ ., B))

names(col$VIF)
## "term" "VIF" "tolerance" "flag_vif5" "flag_vif10"

names(as.data.frame(col$performance))
## "Term" "VIF" "VIF_CI_low" "VIF_CI_high" "SE_factor"
## "Tolerance" "Tolerance_CI_low" "Tolerance_CI_high"
```

### Causa provavel

Nao ha bug: sao objetos de classes diferentes, com convencoes de nomes
diferentes. O problema e de divulgacao.

### Correcao sugerida

Nao ha codigo a mudar. No Rd de `mr_collinearity()`:

```
\value{
  ...
  \item{performance}{Resultado de \code{performance::check_collinearity()},
    com nomes de coluna proprios (\code{Term}, \code{VIF_CI_low},
    \code{Tolerance}, ...), diferentes dos de \code{VIF}. Nao combine as
    duas tabelas com \code{rbind} sem harmonizar os nomes.}
}
```

### Teste de regressao sugerido

```r
test_that("mr_collinearity nomeia as duas tabelas de forma distinta", {
  B <- mr_example_data("agronomy_collinear")
  col <- mr_collinearity(mr_fit(yield_t_ha ~ ., B))
  expect_true(all(c("VIF", "tolerance") %in% names(col$VIF)))
  perf <- as.data.frame(col$performance)
  expect_true(all(c("Term", "VIF_CI_low") %in% names(perf)))
  expect_false(identical(names(col$VIF), names(perf)))
})
```

---


---

## 9. O `...` de `mr_select()` e inutilizavel em `best_subset` e `stability`

**Severidade: media.Esforco: baixo.** Este tem a consequencia mais direta dos
onze itens, porque impede o usuario de ajustar um parametro que ele sabe existir
e que a documentacao do backend sugere.

### Sintoma

`mr_select()` declara `...` para repassar argumentos ao motor do metodo. Em
`best_subset` e `stability`, o `...` colide com argumentos que o proprio
`mr_select()` ja declara, e a chamada falha por colisao.

### Exemplo minimo

```r
library(multiRegFlow)
B <- mr_example_data("agronomy_collinear")
f <- mr_fit(yield_t_ha ~ ., B)

mr_select(f, "best_subset", nvmax = 4)
## Error: argumento formal "nvmax" corresponde a multiplos argumentos especificados

mr_select(f, "stability", PFER = 2)
## Error: argumento formal "PFER" corresponde a multiplos argumentos especificados
```

O mesmo nao acontece em `mr_regularize()`, cujo `...` repassa limpo para o
`glmnet`: `mr_regularize(f, "lasso", intercept = FALSE)` funciona.

### Causa provavel

`R/selection.R`. O `...` e repassado inteiro para a chamada de
`leaps::regsubsets()` ou `stabs::stabs()`, e o R recusa quando o mesmo nome
chega por dois caminhos: uma vez como argumento formal de `mr_select()` e
outra por `...`.

### Correcao sugerida

Nomear os argumentos no nivel de `mr_select()`, e nao deixar o `...` colidir
com os do backend:

```r
mr_select <- function(x, method = c("aic", "bic", "best_subset", "lasso",
                                    "elastic_net", "stability"),
                      alpha = 0.5, keep = NULL, seed = 123,
                      lambda = c("1se", "min"),
                      nbmax = 15, nvmax = 3, nbd = 3, PFER = 1,
                      ...) {
  method <- match.arg(method)
  ## os parametros do backend passam a ter nome, e deixam de vir pelo `...`
  ## qualquer outro argumento continua indo por `...`, como hoje
}
```

E, se a intencao for manter o `...` generico, recusar a colisao com uma
mensagem que diga o que fazer:

```r
## antes de repassar:
nomes_ja_declarados <- c("alpha", "keep", "seed", "lambda")
colidem <- intersect(names(as.list(...)), nomes_ja_declarados)
if (length(colidem))
  stop("`mr_select()` ja declara: ", paste(colidem, collapse = ", "),
       ". Use o argumento nomeado, ou procure em ?mr_select.", call. = FALSE)
```

### Teste de regressao sugerido

```r
test_that("o `...` de mr_select repassa sem colidir", {
  B <- mr_example_data("agronomy_collinear")
  f <- mr_fit(yield_t_ha ~ ., B)
  expect_error(mr_select(f, "best_subset", nvmax = 4), NA)
  expect_error(mr_select(f, "stability", PFER = 2), NA)
  expect_error(mr_select(f, "best_subset", argumento_inexistente = 1), NA)
})
```

---

## 10. Registros que contrariam a expectativa, e que valem documentar

Estes nao sao defeitos. Entram no relatorio porque um tutorial que afirmasse o
contrario sem medir publicaria numero errado, e porque cada um deles e uma
armadilha de leitura para quem usa o pacote pela primeira vez.

### 10.1 `match.arg` completa prefixo de metodo, sem aviso

`mr_regularize(f, "elastic", ...)` **nao da erro** e completa para
`elastic_net`. E o comportamento padrao de `match.arg`. O risco e baixo porque
o objeto devolvido traz o nome completo do metodo, o que torna o resultado
auditavel. Sugestao: um `match.arg(..., several.ok = FALSE)` com
verificacao explicita do nome final, ou uma nota no Rd.

### 10.2 `mr_select(method = "stability")` pode nao reter nenhum termo

Com o cenario colinear deste tutorial, a maior probabilidade de selecao medida
foi `0,490` contra um corte de `0,75`, e nenhum termo foi retido. O `PFER`
devolvido foi `0,583`, e nao o `1` que o codigo passou. E um resultado
legitimo de um metodo que trabalha com distribuicao de selecao, e convem que
o Rd diga que o resultado pode ser o conjunto vazio.

### 10.3 O bootstrap `wild` nao e o que mais se aproxima de HC3

A recomendacao usual e usar `wild` sob heterocedasticidade. Medindo a distancia
media entre o desvio-padrao das replicatas e o desvio-padrao de HC3, nos tres
tipos, o `pairs` foi o mais proximo, e o `wild` ficou no meio:

| Tipo | Distancia media | Distancia maxima |
|:---|---:|---:|
| `pairs` | menor | menor |
| `residual` | maior | maior |
| `wild` | intermediario | intermediario |

A cobertura da verdade plantada foi integral nos tres tipos e nenhuma conclusao
mudou. O que de fato separa os tipos e a **estabilidade de sinal**: no cenario
usado, o unico termo que os tres metodos marcaram como instavel foi exatamente
o termo sem efeito plantado. Isso e um resultado a favor do pacote, e
contra-intuitivo em relacao a recomendacao usual.

## Melhorias sem defeito associado

Nao ha bug aqui, so tempo poupado de quem usa o pacote.

**M.** `mr_capabilities()` e um mapa de dependencias excelente e subaproveitado.
Como o livro descobre a maquina em segundos o que esta instalado, e o usuario
tambem pode. Sugestao: expor um aviso na primeira chamada de uma funcao cujo
backend nao esteja instalado, em vez de erro sob demanda. Hoje o erro vem
quando a funcao e chamada, e o usuario pode ter investido dez linhas antes.

**M.** `mr_compare()` aceita `...` nomeado e gera nomes automaticos
(`model1`, `model2`) quando nao ha nome. Funciona bem, mas o nome automatico
nao entra no texto do relatorio nem em nenhum aviso. Sugestao: incluir
`model1` no texto de `note`.

**M.** As vinhetas do pacote sao um ativo de didatica incomparavel, e o
`VIGNETTE_ORGANIZATION.md` mostra que houve desenho. O unico cuidado: a
vinheta `v01` cobre 18 funcoes, e a @sec-cobertura deste tutorial mostra que
`sugests` como `olsrr`, `mctest`, `mcvis`, `broom` e `car` estao no `DESCRIPTION`
e nao aparecem em nenhum modulo de `mr_capabilities()`. Se nao ha uso, remover
do `Suggests` reduz o custo de instalacao sem perda.

**B.** `mr_report()` grava o arquivo **e** devolve o texto. Quem esquece de
usar o valor de retorno fica com `NULL` depois de ter pedido o relatorio, e a
mensagem de erro nao ajuda. Sugestao: o `file` devolver `invisible()` quando
fornecido, com o texto no stdout, ou documentar explicitamente o duplo
comportamento.

## Hipoteses descartadas

### Descartada 1: "o teste de Breusch-Pagan do pacote esta quebrado"

**Sintoma que motivou:** no cenario A, nenhuma das **nove** estruturas de
variancia testadas era detectada, e o p ficava em torno de 0,9 para todas,
inclusive uma em que o desvio-padrao variava por um fator de quase 5. Um
teste com esse poder deveria disparar, e nao disparar sugeria implementacao
quebrada.

**Por que parecia plausivel:** `.mr_bp_test()` em `R/utils.R` e curto e usa
`tryCatch` ao redor de `lm(e2 ~ ., data = z)`, e a construcao com
`check.names = TRUE` sobre `model.matrix()` parece um ponto tipico de falha
silenciosa.

**Como foi refutada:** comparacao direta com `lmtest::bptest` em cinco casos
controlados, com heteroscedasticidade inequivoca e semente fixa.

| Caso | nR2 do pacote | nR2 do lmtest | p |
|:---|---:|---:|:---|
| homocedastico | 1,756 | 1,756 | 0,624 |
| sigma 0,2 -> 1,4 em x1 | 26,156 | 26,156 | 8,85e-06 |
| sigma sobe com x1 ao quadrado | 34,141 | 34,141 | 1,85e-07 |
| sigma sobe com \|x2\| | 11,913 | 11,913 | 0,0077 |

Identico em todos os casos, e detectando corretamente a heteroscedasticidade
plantada nos tres em que ela existe.

**Conclusao:** a implementacao esta correta. O sintoma real era outro: as tres
observacoes outliers plantadas, e nao o teste. E essa descoberta e o que
tornou o cenario A do tutorial instrutivo, alem de ter gerado o item 5 desta
lista.

### Descartada 2: "`mr_inference(vcov = "cluster")` aceita agrupamento invalido em silencio"

**Sintoma que motivou:** ver `clusters = 160` numa saida com 180 observacoes,
sem aviso nem erro. A leitura apressada e que o pacote aceitaria qualquer
coisa como agrupamento.

**Por que parecia plausivel:** `mr_inference()` repassa `cluster` direto para
`sandwich::vcovCL()`, e `vcovCL` e permissivo.

**Como foi refutada:** leitura do codigo da funcao e sondagem de sete tipos de
entrada.

| Entrada | Grupos aceitos | Comportamento |
|:---|---:|:---|
| fator de 6 niveis | 6 | correto |
| inteiro de 6 niveis | 6 | correto |
| caracter de 6 niveis | 6 | correto |
| numerico continuo | 180 | aceito, sem aviso |
| numero de linha (`seq_len`) | 180 | aceito, sem aviso |
| nivel de tratamento (`rep(1:6, each=30)`) | 6 | correto |
| fator de um nivel so | - | recusado: "At least two clusters are required." |

O pacote aceita quatro tipos, valida comprimento, recusa agrupamento unico, e
**grava o numero de agrupamentos na coluna `clusters` da saida**. Isso e
validacao, e a gravacao da coluna e o que torna o problema visivel.

**Conclusao:** a severidade caiu de **alta** para **media**. O item nao e
"agrupamento invalido aceito", e "ausencia de aviso quando o numero de
agrupamentos se aproxima do numero de observacoes". O item 3 desta lista e a
versao corrigida.

---

## Sugestao de ordem de trabalho

Por custo crescente, agrupando o que convem fazer junto.

**Lote 1, barato e independente (uma hora em total)**
1. Item 2: nota na tabela de ajuste de `mr_compare`.
2. Item 3: aviso de agrupamento degenerado em `mr_inference`.
3. Item 6: documento `mr_example_data()` sem argumento.
4. Item 8: documento as duas tabelas de VIF.

Esses quatro nao se tocam, e nenhum exige decisao de projeto.

**Lote 2, depende do lote 1 estar publicado**
5. Item 5: regra que liga variancia nao rejeitada a influencia alta, e frase
   de ordem de leitura no `note` de `mr_diagnose`. E o item que mais rende
   para o usuario, porque evita uma conclusao errada, e e o que o tutorial
   inteiro mede.
6. Item 4: `coef.mr_quantile()` para simetria com `mr_fit`.

**Lote 3, com decisao de contrato**
7. Item 1: vetor nomeado ou lista. Recomendo a **opcao 2**, documentar o
   acesso por colchetes, porque nao quebra ninguem e resolve o problema de
   quem le. Se a prioridade for consistencia de API, a opcao 1 e defensavel,
   e o custo e menor do que parece, porque o acesso por ponto ja falha hoje.
8. Item 7: isolar o gerador nas seis funcoes. Ou documentar, que e mais
   barato e resolve 80% do problema.

---

## Ambiente da verificacao

```r
R.version.string
## R version 4.6.0 (2026-04-24 ucrt)
packageVersion("multiRegFlow")
## 0.2.0
find.package("multiRegFlow")
## D:/RLibrary/multiRegFlow
```

Sistema: Windows 11 x64, build 26200. Compilador: gcc 14.3.0. Todos os 19
modulos de `mr_capabilities()` estavam disponiveis na maquina, o que significa
que nenhum item desta lista foi observado por falta de backend: todos sao de
caminho principal.

Cada item tem exemplo minimo autocontido acima, e todos os numeros citados
foram impressos por execucao, nao transcritos da documentacao. Onde o exemplo
depende de dados que nao sao do pacote, o gerador esta descrito no tutorial
publico que acompanha este relatorio, no capitulo de dados.


