# CHANGE-002 — Contexto e contagem por local

**Status:** ARQUITETURA APROVADA / PLANEJADO  
**Domínios:** Insumos, Contagem, CD

## Problema
`categoria`, `categoria_loja`, `categoria_cd` e `setores[]` misturam conceitos.

As duas contagens precisam ser melhoradas urgentemente.

## Estado alvo

Criar contexto:

`insumo_contexto_estoque`

Conceitualmente:
- insumo_id
- local: LOJA/CD
- setor
- categoria_id
- dias_contagem_override
- ativo

## Herança
Categoria do contexto define padrão.
Insumo/contexto pode sobrescrever.

## View
Criar:
`vw_itens_contagem`

Deve calcular:
- classificação;
- saldo local;
- última contagem;
- política efetiva;
- deve_contar_hoje.

## Migração
Migrar gradualmente:
- `categoria_loja`
- `categoria_cd`
- `setores[]`

Não remover campos antigos até validar equivalência.

## Critérios de aceite
- [ ] Tampa 550 aparece na Loja e no CD;
- [ ] categoria Loja difere da categoria CD;
- [ ] dias Loja diferem dos dias CD;
- [ ] tomate matéria-prima aparece no CD, não na Loja;
- [ ] produzido internamente pode ser contado no CD;
- [ ] item direto aparece na Loja sem exigir CD;
- [ ] categoria define default;
- [ ] override individual funciona.
