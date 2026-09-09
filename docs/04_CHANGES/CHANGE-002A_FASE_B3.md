# CHANGE-002A — Fase B3

**Status:** PRONTA PARA IMPLEMENTAÇÃO  
**Data:** 09/09/2026

## Objetivo

Definir a política de reposição da Loja por **categoria como padrão**, permitindo **override por insumo/contexto** apenas quando necessário.

A política efetiva será resolvida assim:

```text
politica_reposicao_efetiva
=
override_do_insumo
?? padrao_da_categoria
```

Ou seja:

- a categoria define o comportamento normal;
- o insumo só armazena exceção;
- `NULL` no override significa “herdar da categoria”.

## Políticas possíveis na Loja

### `VOLUME`

Usa:

- `estoque_gatilho`
- `estoque_ideal`

Exemplo: Refrigerantes.

### `META_DIA`

Usa metas físicas por dia da semana.

Exemplo: Embalagens operacionais de açaí.

## CD

Nada muda no CD.

O CD continua sempre operando por **VOLUME**.

## Política de contagem

Continua independente da política de reposição.

A mesma categoria/local pode possuir:

- uma política padrão de contagem;
- uma política padrão de reposição.

O insumo/contexto pode sobrescrever ambas quando necessário.

## Estratégia da Fase B3

### Etapa 1 — Diagnóstico por categoria

Listar as categorias da Loja mostrando:

- total de itens;
- quantos possuem `meta_estoque` histórica;
- quantos possuem gatilho/ideal preenchidos;
- quantos estão `0/0`;
- valor legado de `compra_diaria` apenas como evidência histórica.

O objetivo é permitir decisão rápida do padrão da categoria.

### Etapa 2 — Definir padrão da categoria

Para cada categoria da Loja, escolher:

- `VOLUME`
- `META_DIA`

Essa escolha será persistida como política padrão da categoria/local.

### Etapa 3 — Exceções

Depois da definição dos padrões, listar somente os insumos que precisam divergir da categoria.

Exemplos:

- categoria normalmente `VOLUME`, mas um item específico usa `META_DIA`;
- categoria normalmente `META_DIA`, mas um item específico usa `VOLUME`.

Esses casos recebem override no `insumo_contexto_estoque`.

## Mudança de schema necessária

O modelo precisa suportar:

### Na categoria/local
Uma política padrão de reposição para a Loja.

### No contexto do insumo
Um override opcional:

```text
modo_reposicao_loja_override
NULL | VOLUME | META_DIA
```

`NULL` significa herdar da categoria.

## Importante

- `compra_diaria` não define a política nova;
- `meta_estoque` histórica não define sozinha a política nova;
- `gatilho/ideal = 0/0` não bloqueia a classificação;
- a classificação será feita primeiro por categoria;
- nenhum item precisa ser configurado individualmente se seguir o padrão da categoria.

## Critério de aceite

A Fase B3 termina quando:

1. todas as categorias de Loja possuem política padrão definida;
2. exceções por insumo estão identificadas;
3. a regra de herança categoria → insumo está documentada e pronta para implementação;
4. nenhum consumidor antigo foi quebrado.
