# LEIA-ME: como gerar e o que e cada arquivo

Este livro e um tutorial auditado do pacote **multiRegFlow** 0.2.0, para
agronomia, solo e fisiologia vegetal. Todo numero da prosa e interpolado de um
objeto calculado no render, e a cobertura da API e calculada, nao afirmada.

## Como gerar

```powershell
# 1. o pacote instalado tem de estar visivel
#    (o livro aponta para D:/RLibrary; ajuste em _common.R se for outro)

# 2. ensaio seco: executa o codigo de cada capitulo em segundos,
#    sem pagar o custo do Quarto. Rodar SEMPRE antes do render.
cd D:\Walter\R\Pacotes_criados\Tutoriais\multiRegFlow\livro
Rscript --vanilla _dryrun2.R

# 3. confere tipografia: travessao, espaco duro e caractere nao-ASCII
Rscript --vanilla _check_ascii.R

# 4. render. Os DOIS formatos numa unica invocacao, porque renderizar
#    um formato isolado limpa o diretorio de saida e apaga o outro.
quarto render .
```

Depois do passo 4:

- `_book/` contem o site HTML, um arquivo por capitulo, com o codigo embutido
  e os recursos embutidos. Abre sozinho, sem internet.
- `_book/multiRegFlow-na-pratica.pdf` e o **PDF unico** com todos os capitulos.
  Nao ha juncao manual: em projeto do tipo livro, o Quarto concatena os
  capitulos e emite um so arquivo.

## Por que LaTeX e nao Tipst

Este livro usa o formato `pdf` com `documentclass: scrreprt` do koma-script, e
nao Tipst. A escolha foi medida, nao presumida.

O Tipst vem embutido no Quarto e nao depende de nada externo, o que o torna
atractivo. Nesta maquina, **porem, o Typst falha em todo render**, e a falha
nao e do conteudo: um livro de dois capitulos com uma tabela, uma figura e um
callout tambem falha, com `error: expected content, found array`. A falha
aparece na compilacao do `index.typ`, antes de qualquer conteudo do livro, o
que aponta para o binario do Typst empacotado no Quarto 1.11.0 desta
instalacao, e nao para o projeto.

O LaTeX esta instalado via TinyTeX, com `pdflatex`, `xelatex` e `lualatex`
disponiveis, e o `scrreprt` do koma-script renderizou o livro minimo sem
erro. Se voce quiser voltar ao Tipst depois de uma atualizacao do Quarto, e so
trocar o bloco `pdf` por `typst` no `_quarto.yml`; nada no codigo dos
capitulos depende do formato.

Para conferir se o Tipst voltou a funcionar nesta maquina:

```powershell
quarto render livro --to typst
## se aparecer "error: expected content, found array", o problema persiste
```

## O que e cada arquivo

| Arquivo | O que e |
|:---|:---|
| `_quarto.yml` | configuracao do projeto. Dois formatos: HTML e Tipst. `lang: pt`. |
| `_common.R` | **infra-estrutura do livro inteiro.** Formatacao, tabelas, cache, registro de uso, geradores de cenario, tema das figuras. |
| `index.qmd` | apresentacao, contrato do livro, mapa dos modulos, o que o livro nao faz. |
| `01-dados-e-verdade-plantada.qmd` | os seis cenarios, a verdade plantada, e a prova de que cada discrepancia existe. |
| `02-ajuste-e-diagnostico.qmd` | `mr_fit`, `mr_diagnose`, `mr_influence`, `mr_recommend`, e o achado dos outliers que mascaram a variancia. |
| `03-colinearidade-e-inferencia.qmd` | `mr_collinearity`, `mr_inference`, e a leitura obrigatoria da coluna `clusters`. |
| `04-selecao-e-regularizacao.qmd` | `mr_select`, `mr_regularize`. |
| `05-reamostragem.qmd` | `mr_bootstrap`, os tres tipos e os tres intervalos. |
| `06-importancia-e-efeitos.qmd` | `mr_importance`, `mr_effects`, e por que as medidas nao sao intercambiaveis. |
| `07-motores-flexiveis.qmd` | os cinco motores de `mr_fit`, `mr_quantile`, `mr_kernel`, com o custo medido. |
| `08-validacao-e-comparacao.qmd` | `mr_validate`, `mr_compare`, e a separacao entre ajuste e previsao. |
| `09-relatorio-e-auditoria.qmd` | `mr_report`, `mr_capabilities`, `mr_example_data`, e o `NA` silencioso. |
| `10-crista-e-otimo-condicional.qmd` | o caso da cresta: o otimo condicional que nenhuma analise univariada ve, e o que custa ignora-lo. |
| `11-cobertura-da-api.qmd` | a tabela de cobertura **calculada**, e as tres lacunas que ela tem. |
| `99-nota-tecnica.qmd` | os oito achados, as duas hipoteses descartadas, e o que o pacote faz bem. |
| `RELATORIO-AO-AUTOR.md` | o mesmo material por severidade, com correcao em codigo e teste de regressao por item. |
| `_dryrun2.R` | ensaio seco. Apagar antes de publicar. |
| `_check_ascii.R` | verificador de tipografia. Apagar antes de publicar. |
| `_artefatos/` | cache, registro de uso e decisoes por capitulo. **Entregar junto.** |
| `_book/` | saida. Nao versionar. |

## Politica de repeticoes e de cache

Todos os cenarios usam semente fixa, declarada dentro de `_common.R`.
**Trocar a semente muda todos os numeros do livro**, inclusive os das frases.

| Onde | Politica |
|:---|:---|
| Bootstrap | `R = 500` nos capitulos, `seed` explicito |
| Validacao cruzada | `v = 5` a `10` dobras, `2` a `5` repeticoes, `seed` explicito |
| Estabilidade de selecao | `seed` explicito |
| Gens de figura | nenhum: figura nao sorteia |

O cache fica em `_artefatos/cache-*.rds` e e indexado pelo codigo do bloco e
pelas dependencias declaradas. Mudar um valor descarta o cache correspondente
sozinho. Para forcar o recalculo total, apague o conteudo de `_artefatos/`.

**Entregue o cache junto com os fontes.** Sem ele, o primeiro render do
leitor recalcula tudo e leva mais tempo, e o leitor nao sabe se os numeros que
ve batem com os do livro.

## Forcar recalculo

```powershell
# so um capitulo
quarto render livro/02-ajuste-e-diagnostico.qmd

# tudo, so HTML, para iterar rapido
quarto render livro --to html

# a entrega final tem de ser o render duplo numa unica invocacao
quarto render livro
```

## Verificacoes que este livro roda

| O que | Como | Criterio |
|:---|:---|:---|
| codigo executa | `_dryrun2.R` | `OK` em todos os capitulos |
| tipografia | `_check_ascii.R` | `TOTAL DE ACHADOS: 0` |
| sem travessao | `_check_ascii.R` | ja incluso |
| campos vazios e `NA` no output | inspecao da saida do ensaio seco | nenhum campo interpolado vazio |
| cobertura da API | capitulo 11 | tabela calculada, nao afirmada |
| rotulos de bloco duplicados | varredura por `#\| label:` | zero repeticoes |
| referencias cruzadas | log do render | zero `Unable to resolve crossref` |
| ambos os formatos | log do render | nenhum `not supported by book projects` |

## Regras que o livro segue, e que um capitulo novo precisa seguir

1. Nenhum comportamento descrito antes de ser executado.
2. Nenhum numero digitado na prosa.
3. A cobertura e calculada, nao afirmada.
4. Uma realizacao ilustra; repeticoes concluem.
5. Todo capitulo fecha com `usar()`, `salvar_uso()` e `salvar_decisoes()`.
6. Todo achado e atacado antes de virar texto.
7. Todo estudo entrega o relatorio ao autor.

Mais duas, de forma pratica:

- **ASCII apenas.** Sem acento, sem cedilha, sem travessao. O
  `_check_ascii.R` falha o build se houver.
- **Rotulo de bloco unico** em todo o livro. Dois `#| label:` iguais em
  capitulos diferentes colidem no Quarto.

## Para adicionar um capitulo

1. Crie o arquivo `NN-nome.qmd`, comeca em letra e nome unico.
2. Primeiro bloco: `source("_common.R")` com `include: false`.
3. Use `usar("funcao", argumento = valor)` **na chamada real**, para que o
   argumento entre na cobertura.
4. Ultimo bloco: `salvar_uso("NN")` e `salvar_decisoes("NN", ...)`.
5. Adicione o arquivo a lista `chapters` do `_quarto.yml`.
6. Rode `_dryrun2.R`, depois `_check_ascii.R`, depois o render.
7. O capitulo 11 mostra a cobertura atualizada sem nenhuma edicao: ela e
   calculada a partir do registro.

## O relatorio ao autor

`RELATORIO-AO-AUTOR.md` tem oito itens, nenhum de severidade alta, cada um com
exemplo minimo, causa provavel, correcao em codigo e teste de regressao. Ele
inclui duas **hipoteses descartadas**, com a refutacao completa, para que
ninguem gaste tempo investigando o que ja foi investigado.

Os quatro itens do primeiro lote custam cerca de uma hora em total, sao
independentes entre si e nenhum exige decisao de projeto.

