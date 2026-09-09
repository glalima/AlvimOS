# ADR-006 — Contexto de estoque por local e semântica das chaves logísticas

**Status:** ACEITO  
**Data:** 09/09/2026  
**Projeto:** ALVIM OS  
**Domínios:** Insumos, Estoque, Contagem, Reposição e Compras  
**Substitui parcialmente:** ADR-002 e regras anteriores baseadas em `compra_diaria`

## 1. Contexto

O modelo anterior utilizava `produzido_internamente`, `recebido_no_cd`, `enviado_loja` e `compra_diaria`. A evolução do sistema mostrou que `compra_diaria` misturava frequência de contagem, reposição da Loja e compras, enquanto os nomes das outras chaves não expressavam com precisão sua regra de negócio.

A arquitetura passa a separar origem, local de controle, contagem, reposição e compra.

## 2. Decisão

### `produzido_internamente`
Pergunta: este insumo é produzido/obtido internamente e, portanto, não deve gerar compra de fornecedor?

- `true` exclui o insumo do motor normal de compras externas;
- `true` exige contexto CD.

### `recebido_externamente_no_cd`
Substitui conceitualmente `recebido_no_cd`.

Pergunta: este insumo comprado externamente é recebido e estocado no CD?

- `true` exige contexto CD;
- compras externas usam o contexto CD.

### `controlado_na_loja`
Substitui conceitualmente `enviado_loja`.

Pergunta: este insumo precisa ter saldo físico controlado na Loja?

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

## 4. Exemplos

**Tampa 550 ml:** `false / true / true` → CD + LOJA. CD por volume; Loja pode usar META_DIA.

**Tomate inteiro:** `false / true / false` → somente CD.

**Produzido internamente e controlado na Loja:** `true / false / true` → CD + LOJA e fora das compras externas.

**Coca entregue diretamente pelo fornecedor na Loja:** `false / false / true` → somente LOJA; compra externa abastece Loja.

## 5. Reposição

### CD
Sempre por VOLUME:

```text
saldo <= estoque_gatilho
→ necessidade = estoque_ideal - saldo
```

### Loja
Pode operar por:

- `VOLUME`: `estoque_gatilho` + `estoque_ideal`;
- `META_DIA`: meta física por dia da semana.

```text
necessidade = MAX(meta_do_dia - saldo_loja, 0)
```

## 6. Contagem

Contagem é independente da reposição.

```text
CATEGORIA + LOCAL
→ política padrão

INSUMO + LOCAL
→ override opcional
```

## 7. `compra_diaria`

`compra_diaria` está **DEPRECATED** e não deve participar de novas regras.

Permanece temporariamente por compatibilidade até a migração completa. A existência de `meta_estoque` histórica não prova que o item atualmente opere por `META_DIA`.

## 8. Contexto por local

`insumo_contexto_estoque` passa a representar a configuração operacional por `CD` ou `LOJA`.

Contém categoria, política/override de contagem, parâmetros de volume, modo de reposição da Loja e estado de ativação durante a migração.

O setor é derivado de `categorias.setor`, evitando duplicação.

## 9. Metas

`meta_estoque_contexto` representa metas do contexto LOJA:

```text
contexto_id
dia_semana
quantidade
```

Metas não são obrigatórias para todo item controlado na Loja.

## 10. Painel de Compras

```text
produzido_internamente = true
→ não gerar compra externa
```

Para compra externa:

```text
recebido_externamente_no_cd = true
→ usar contexto CD
```

Caso contrário, se `controlado_na_loja = true`, a compra pode abastecer diretamente a Loja.

Não usar `saldo_total` indiscriminadamente.

## 11. Migração e nomes físicos

A migração é progressiva. Durante a transição, os nomes físicos antigos continuam temporariamente:

```text
recebido_no_cd → recebido_externamente_no_cd
enviado_loja   → controlado_na_loja
```

Nenhuma renomeação física ocorre antes da varredura de dependências e migração dos consumidores.

## 12. Casos obrigatórios

1. Coca-Cola 2L — Loja por VOLUME.
2. Tampa 550 — CD por VOLUME + Loja por META_DIA.
3. Tomate inteiro — somente CD.
4. Compra entregue diretamente à Loja.
5. Produzido internamente controlado no CD/Loja.
6. Meta histórica que não representa mais política atual.

## 13. Consequência

```text
INSUMO    → o que é / como se origina
CONTEXTO  → onde o estoque é controlado
CONTAGEM  → quando conferir
REPOSIÇÃO → quanto recompor
COMPRA    → quando e para qual local comprar
```

Este modelo substitui a tentativa de fazer `compra_diaria` e nomes de fluxo responderem simultaneamente a essas perguntas.
