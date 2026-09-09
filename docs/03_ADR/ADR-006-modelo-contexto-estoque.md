# ADR-006 — Evolução do modelo logístico para contexto de estoque por local

**Status:** PROPOSTO  
**Data:** 09/09/2026  
**Domínios:** Insumos, Estoque, Contagem, Reposição, Compras

## Contexto

O modelo anterior utilizava quatro chaves booleanas no cadastro de insumos:

- `produzido_internamente`
- `recebido_no_cd`
- `enviado_loja`
- `compra_diaria`

A análise dos fluxos reais mostrou que `compra_diaria` mistura responsabilidades que agora são melhor representadas por políticas de contagem e por parâmetros de estoque específicos de cada local.

Também ficou claro que um mesmo insumo pode possuir comportamentos diferentes na Loja e no CD.

Exemplos:
- Coca-Cola 2L: Loja controlada por volume, sem metas diárias.
- Tampa 550 ml: CD controlado por volume; Loja controlada por metas por dia.
- Tomate inteiro: existe no CD como matéria-prima e não precisa existir na Loja em sua forma original.
- Item entregue diretamente na Loja: `recebido_no_cd = false` e `enviado_loja = true`.

## Decisão proposta

O modelo passa a utilizar três características logísticas globais:

### `produzido_internamente`
Indica que o item é produzido ou transformado internamente.

### `recebido_no_cd`
Indica que o item possui entrada externa fisicamente pelo CD.

### `enviado_loja`
Indica que o item existe e precisa ser controlado fisicamente na Loja, independentemente de vir do CD ou diretamente do fornecedor.

A chave `compra_diaria` passa a ser considerada **DEPRECATED** e não deve ser utilizada em novas regras.

Ela não será removida do banco antes de uma varredura completa de dependências.

## Contexto de estoque por local

A classificação e o comportamento de estoque passam a pertencer ao contexto do insumo em cada local.

Modelo conceitual:

`INSUMO → CONTEXTO DE ESTOQUE → LOCAL`

Cada contexto poderá conter:
- local (`LOJA` ou `CD`);
- setor;
- categoria;
- política de contagem;
- override de dias de contagem;
- estoque gatilho;
- estoque ideal;
- ativo.

## Regra do CD

O estoque do CD é sempre controlado por **volume**.

Quando aplicável:

`saldo_cd <= estoque_gatilho`

gera necessidade de recomposição até:

`estoque_ideal`

Para itens recebidos externamente no CD, essa necessidade normalmente será atendida por compra.

## Regra da Loja

A Loja poderá ter dois comportamentos:

### Volume
Usa:
- `estoque_gatilho`
- `estoque_ideal`

Exemplo: Coca-Cola 2L.

### Meta por dia
Usa metas operacionais por dia da semana.

Exemplo: Tampa 550 ml na Loja.

A meta diária representa exclusivamente o alvo físico operacional da Loja.

## Política de contagem

A frequência de contagem é independente da política de recomposição.

Ela deve ser configurável por:

`categoria/local → padrão`

e:

`insumo/local → override opcional`

A mesma mercadoria pode ter frequências diferentes na Loja e no CD.

## Metas diárias

As metas devem ser relacionadas explicitamente ao contexto de estoque da Loja.

Modelo sugerido:

`meta_estoque_contexto`

- `contexto_id`
- `dia_semana`
- `quantidade`

com unicidade por `(contexto_id, dia_semana)`.

## Consequências

1. `ADR-002` deverá ser marcado como parcialmente substituído por este ADR quando aprovado.
2. `compra_diaria` não será usada em lógica nova.
3. `CHANGE-002` deverá ser dividido em:
   - `CHANGE-002A` — contexto por local + migração;
   - `CHANGE-002B` — contagem Loja/CD por contexto.
4. `CHANGE-003` deverá usar o saldo do contexto abastecido, e não assumir `saldo_total`.
5. Campos globais como `gatilho_pedido` e `estoque_ideal` deverão ser avaliados para migração ao contexto local.
6. Campos legados não serão removidos até o novo modelo estar validado.

## Não decidido ainda

- nome final de `enviado_loja`;
- momento exato de migração de `gatilho_pedido` e `estoque_ideal`;
- regra completa para itens entregues diretamente à Loja;
- estratégia de compatibilidade durante a coexistência entre schema antigo e novo.

## Critério para ACEITAR este ADR

Antes de mudar o schema, concluir a varredura de dependências de `compra_diaria` e validar os principais casos reais de estoque.
