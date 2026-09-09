# ADR-006 — Contexto de estoque por local, chaves logísticas e herança por categoria

**Status:** ACEITO  
**Data:** 09/09/2026  
**Projeto:** ALVIM OS  
**Domínios:** Insumos, Estoque, Contagem, Reposição e Compras  
**Substitui parcialmente:** ADR-002 e regras anteriores baseadas em `compra_diaria`

## 1. Contexto

O modelo anterior utilizava `produzido_internamente`, `recebido_no_cd`, `enviado_loja` e `compra_diaria`.

A evolução do sistema mostrou que `compra_diaria` misturava responsabilidades de contagem, reposição e compras. Também ficou claro que um mesmo insumo pode ter comportamentos diferentes conforme o local físico onde é controlado.

A arquitetura passa a separar:

1. origem do insumo;
2. local de controle de estoque;
3. política de contagem;
4. política de reposição;
5. política de compra.

## 2. Chaves logísticas globais

### `produzido_internamente`

Pergunta de negócio:

> Este insumo é produzido/obtido internamente e, portanto, não deve gerar compra de fornecedor?

Regras:
- `true` exclui o insumo do motor normal de compras externas;
- `true` exige contexto CD.

### `recebido_externamente_no_cd`

Substitui conceitualmente `recebido_no_cd`.

Pergunta de negócio:

> Este insumo comprado externamente é recebido e estocado no CD?

Regras:
- `true` exige contexto CD;
- compras externas usam o contexto CD.

### `controlado_na_loja`

Substitui conceitualmente `enviado_loja`.

Pergunta de negócio:

> Este insumo precisa ter saldo físico controlado na Loja?

Regras:
- `true` exige contexto LOJA;
- não significa necessariamente transporte CD → Loja;
- fornecedor pode entregar diretamente à Loja.

## 3. Derivação dos contextos

```text
CONTEXTO CD
= produzido_internamente
  OR recebido_externamente_no_cd

CONTEXTO LOJA
= controlado_na_loja
```

Contexto representa onde o estoque é controlado fisicamente.

## 4. Exemplo de contextos

### Tampa 550 ml

```text
produzido_internamente = false
recebido_externamente_no_cd = true
controlado_na_loja = true

→ contexto CD
→ contexto LOJA
```

### Tomate inteiro

```text
false
true
false

→ somente contexto CD
```

### Produzido internamente e controlado na Loja

```text
true
false
true

→ contexto CD
→ contexto LOJA
→ fora das compras externas
```

### Compra entregue diretamente à Loja

```text
false
false
true

→ somente contexto LOJA
→ compra externa abastece Loja
```

## 5. Regra do CD

O CD opera sempre por **VOLUME**.

```text
saldo <= estoque_gatilho
→ necessidade = estoque_ideal - saldo
```

Não existe política `META_DIA` para reposição do CD.

## 6. Regra da Loja

A Loja pode operar por:

### `VOLUME`

Usa:
- `estoque_gatilho`;
- `estoque_ideal`.

### `META_DIA`

Usa metas físicas por dia da semana:

```text
necessidade = MAX(meta_do_dia - saldo_loja, 0)
```

## 7. Política padrão por categoria

Cada categoria pertence a um único local operacional.

A categoria passa a ser a **fonte do comportamento padrão** dos insumos daquele grupo.

A tabela `categorias` passa a armazenar:

- `modo_reposicao_padrao`
- `dias_contagem_padrao`
- `ativo_contagem`

A categoria não armazena gatilho nem estoque ideal, pois esses valores continuam específicos do insumo/contexto.

### Regra de herança

O contexto do insumo pode sobrescrever os defaults da categoria.

```text
POLÍTICA EFETIVA
=
override do contexto do insumo
?? padrão da categoria
```

Portanto:

```text
CATEGORIA + LOCAL
→ define o padrão

INSUMO + LOCAL
→ define somente a exceção
```

Se o override estiver `NULL`, o sistema herda a política da categoria.

## 8. Overrides por contexto

`insumo_contexto_estoque` deve conter apenas overrides opcionais das políticas herdáveis, por exemplo:

- `modo_reposicao_loja_override`
- `dias_contagem_override`

O contexto não deve duplicar automaticamente o valor efetivo da categoria.

Isso evita centenas de configurações repetidas e permite alterar uma política operacional de toda uma categoria de forma centralizada.

## 9. Política de contagem

Contagem é independente da política de reposição.

Uma categoria pode ser:

```text
modo_reposicao_padrao = VOLUME
dias_contagem_padrao = {1,5}
```

ou:

```text
modo_reposicao_padrao = META_DIA
dias_contagem_padrao = {1,2,3,4,5,6,7}
```

O insumo pode sobrescrever apenas os dias, apenas a reposição, ambos ou nenhum.

## 10. `compra_diaria`

`compra_diaria` está **DEPRECATED**.

Não deve ser usada em novas regras de negócio.

Permanece temporariamente no schema apenas por compatibilidade durante a migração.

A existência de uma linha histórica em `meta_estoque` também não prova que o item opere atualmente por `META_DIA`.

## 11. Contexto por local

`insumo_contexto_estoque` representa a configuração operacional de um insumo em:

- `CD`;
- `LOJA`.

O contexto contém:
- categoria do local;
- parâmetros de volume específicos daquele local;
- overrides opcionais de política;
- estado de ativação durante a migração.

O setor é derivado da categoria.

## 12. Metas por dia

`meta_estoque_contexto` representa metas do contexto LOJA quando a política efetiva for `META_DIA`.

Estrutura:

```text
contexto_id
dia_semana
quantidade
```

Metas não são obrigatórias para todo item controlado na Loja.

## 13. Painel de Compras

```text
produzido_internamente = true
→ não gerar compra externa
```

Para compras externas:

```text
recebido_externamente_no_cd = true
→ usar contexto CD
```

Caso contrário, se `controlado_na_loja = true`:

```text
→ compra pode abastecer diretamente o contexto LOJA
```

O Painel de Compras não deve usar `saldo_total` indiscriminadamente.

## 14. Migração e nomes físicos

Durante a transição, os nomes antigos continuam fisicamente no banco:

```text
recebido_no_cd → recebido_externamente_no_cd
enviado_loja   → controlado_na_loja
```

A renomeação física ocorrerá somente depois da migração dos consumidores.

## 15. Estratégia de migração

### Fase A
Criar tabelas de contexto sem remover o modelo legado.

### Fase B
Popular contextos e consolidar políticas por categoria.

A política não será inferida item a item a partir de `compra_diaria` ou de metas históricas.

A regra oficial passa a ser:

```text
categoria → default
contexto do insumo → override opcional
```

### Fases posteriores
- migrar consumidores;
- validar contagem;
- validar reposição;
- reconstruir compras;
- remover dependências legadas;
- renomear/remover colunas antigas.

## 16. Casos obrigatórios de validação

1. Coca-Cola 2L — Loja por VOLUME.
2. Tampa 550 — CD por VOLUME + Loja por META_DIA.
3. Tomate inteiro — somente CD.
4. Compra entregue diretamente à Loja.
5. Produzido internamente controlado no CD/Loja.
6. Item com meta histórica que não representa mais política atual.
7. Item que herda política da categoria sem override.
8. Item que sobrescreve o padrão da categoria.

## 17. Consequência arquitetural

```text
INSUMO    → o que é / como se origina
CONTEXTO  → onde o estoque é controlado
CATEGORIA → comportamento operacional padrão
CONTAGEM  → quando conferir
REPOSIÇÃO → quanto recompor
COMPRA    → quando e para qual local comprar
```

A arquitetura passa a privilegiar herança por categoria e exceções explícitas por contexto, reduzindo duplicação de configuração e lógica no frontend.
