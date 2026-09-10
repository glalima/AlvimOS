# CHANGE-002A — Fase B6 — Migração de metas válidas

**Status:** PRONTA PARA EXECUÇÃO

## Diagnóstico aprovado

Foram encontrados:

- 145 contextos LOJA com política efetiva `META_DIA`;
- os 145 possuem meta histórica;
- 0 contextos `META_DIA` sem meta;
- 182 contextos `VOLUME` possuem metas históricas legadas.

## Decisão

Migrar exclusivamente:

`LOJA + META_DIA`

A origem é `meta_estoque` e o destino é `meta_estoque_contexto`.

A estrutura antiga por colunas:

`segunda ... domingo`

é normalizada para sete linhas:

`contexto_id + dia_semana + quantidade`

## Resultado esperado

- 145 contextos migrados;
- 7 metas por contexto;
- 1.015 linhas;
- zero metas novas ligadas a contextos `VOLUME`.

## Legado

As metas históricas dos 182 itens `VOLUME` permanecem em `meta_estoque` temporariamente, mas deixam de possuir significado operacional no modelo novo.

Elas não são apagadas nesta fase para preservar rastreabilidade durante a migração.

## Observação

O item `MORANGO`, categoria `6 - Frutas`, possui meta histórica zero nos sete dias. A migração preserva esse valor fielmente; eventual correção operacional será feita posteriormente.

## Próximo passo

Depois de validar a B6:

1. atualizar `CURRENT_STATE`;
2. fechar checkpoint no Git;
3. criar a fonte SQL da Contagem:
   - local;
   - categoria/setor;
   - saldo;
   - dias efetivos;
   - `deve_contar_hoje`;
   - meta do dia quando `META_DIA`;
4. iniciar CHANGE-002B para migrar as telas Loja/CD.
