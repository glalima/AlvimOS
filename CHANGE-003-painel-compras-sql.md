# CHANGE-003 — Reconstrução do Painel de Compras em SQL

**Status:** PLANEJADO  
**Bloqueio:** consolidar CHANGE-001 e regras principais do CHANGE-002

## Problema
O backend chama uma view ausente no dump.
Regras de compra ainda foram parcialmente confundidas com meta diária.

## Objetivo
Criar `view_painel_compras` como fonte única do painel.

## Princípios aprovados
- compra é diferente de reposição;
- `meta_estoque` é da Loja;
- item recebido no CD compra para o CD por volume;
- saldo relevante depende de onde o fornecedor abastece;
- React não calcula necessidade.

## Caso obrigatório de teste — Tampas
`false / true / true / true`

Esperado:
- compra fornecedor usa saldo CD + gatilho + ideal;
- reposição Loja usa meta Loja.

## Caso obrigatório — Matéria-prima
`false / true / false / false`

Esperado:
- compra considera CD;
- não depende de meta Loja.

## Pendente de formalização
Regra final para todos os casos de compra direta à Loja.

## Critérios de aceite
- [ ] view existe no banco;
- [ ] backend vira SELECT simples;
- [ ] cálculo está em SQL;
- [ ] status e sugestão são reproduzíveis;
- [ ] testes com 5–10 insumos reais;
- [ ] nenhum uso incorreto de meta Loja como ideal CD.
