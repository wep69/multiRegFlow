## _check_ascii.R: o GUIA_COMPLEMENTAR proibe travessao e exige fontes ASCII.
## Barra QUALQUER caractere acima de U+007E, e nao apenas a partir de U+0100:
## acento Latin-1 (U+00E0 e companhia) precisa cair tambem, e e o erro mais
## comum de quem escreve em portugues.
##
## SOBRE O HTML GERADO: o verificador barra travessao, meio travessao e espaco
## duro, mas DEPOIS de remover o que o proprio Quarto emite: o JavaScript de
## busca e de abas, o CSS, e a tag <title>, cujo separador entre titulo e
## subtitulo e um U+2013 gerado pelo proprio Quarto. Esses artefatos do
## gerador nao sao prosa do livro, e contar eles tornaria o verificador
## inutil, porque nunca zeraria. A regra vale para o TEXTO do livro, e o
## TEXTO do livro e o que este script confere.
raiz <- "D:/Walter/R/Pacotes_criados/Tutoriais/multiRegFlow/livro"
alvos <- c(list.files(raiz, pattern = "\\.qmd$", full.names = TRUE),
           file.path(raiz, c("_common.R", "_quarto.yml")))
tem_html <- dir.exists(file.path(raiz, "_book"))
if (tem_html)
  alvos <- c(alvos, list.files(file.path(raiz, "_book"), pattern = "\\.html$",
                               full.names = TRUE, recursive = TRUE))
cat("arquivos varridos:", length(alvos),
    sprintf("(%d .qmd, %d .html)", length(alvos) - 2L,
            sum(grepl("\\.html$", alvos))), "\n\n")

## tira do HTML o que e artefato do gerador, e nao prosa
so_prosa_do_html <- function(linhas) {
  txt <- paste(linhas, collapse = "\n")
  txt <- gsub("(?s)<script[^>]*>.*?</script>", " ", txt, perl = TRUE)
  txt <- gsub("(?s)<style[^>]*>.*?</style>", " ", txt, perl = TRUE)
  txt <- gsub("(?s)<title[^>]*>.*?</title>", " ", txt, perl = TRUE)
  ## comentarios de codigo R exibidos nas celulas de codigo nao sao prosa
  ## autoral, mas sao do livro, entao ficam.
  strsplit(txt, "\n", fixed = TRUE)[[1]]
}

nao_ascii <- function(ln) {
  ch <- strsplit(ln, "")[[1]]
  ch <- ch[ch != "\t"]
  if (length(ch) == 0L) return(integer(0))
  cp <- utf8ToInt(paste(ch, collapse = ""))
  cp[cp < 32L | cp > 126L]
}

achados <- 0L
relatorio <- character(0)

for (f in alvos) {
  t <- tryCatch(readLines(f, warn = FALSE, encoding = "UTF-8"),
                error = function(e) character(0))
  eh_html <- grepl("\\.html$", f)
  if (eh_html) t <- so_prosa_do_html(t)
  for (i in seq_along(t)) {
    ln <- t[i]
    cp <- nao_ascii(ln)
    if (length(cp) == 0L) next
    cods <- unique(sprintf("U+%04X", cp))
    if (eh_html) {
      proibidos_html <- cp[cp %in% c(0x2014L, 0x2013L, 0x00A0L)]
      if (length(proibidos_html) == 0L) next
      cods <- sprintf("U+%04X", proibidos_html)
    }
    achados <- achados + 1L
    relatorio <- c(relatorio, sprintf("%s linha %d: %s | %s",
                                      basename(f), i, paste(cods, collapse = ","),
                                      substr(ln, 1, 90)))
  }
}

cat(paste(relatorio, collapse = "\n"), "\n")
cat("\nTOTAL DE ACHADOS:", achados, "\n")
if (achados > 0L) quit(status = 1L)

