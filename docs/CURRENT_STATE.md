# ALVIM OS — CURRENT STATE

**Data-base:** 06/09/2026  
**Objetivo:** permitir retomar o projeto sem reanalisar todo o repositório.

---

## 1. Trabalho em andamento

### CHANGE-001 — Refatoração do cadastro de insumos
**Status:** PRIORIDADE IMEDIATA

Problemas observados:
- salvar;
- salvar e próximo;
- salvar e anterior;
- edição pode carregar defaults incorretos;
- metas não são carregadas de forma confiável;
- create/update duplicam regras;
- lógica logística está distribuída no TypeScript.

Estado alvo:
- `vw_insumos_cadastro`
- RPC única de persistência (`salvar_insumo`)
- backend fino
- navegação permanece responsabilidade da interface

---

## 2. Próxima mudança estrutural

### CHANGE-002 — Contexto de estoque por local
**Status:** ARQUITETURA APROVADA / A IMPLEMENTAR

Problema:
`categoria`, `categoria_loja`, `categoria_cd` e `setores[]` misturam:
- local físico;
- setor;
- categoria;
- política de contagem.

Estado alvo:

`INSUMO → CONTEXTO LOJA`
e
`INSUMO → CONTEXTO CD`

cada contexto com:
- categoria;
- setor;
- política de contagem;
- possibilidade de override.

---

## 3. Próxima frente funcional

### CHANGE-003 — Painel de Compras
**Status:** BLOQUEADO PELA CONSOLIDAÇÃO DAS REGRAS

O backend atual chama `view_painel_compras`, mas a view não está presente no dump de 06/09/2026.

Antes de implementar:
- estabilizar cadastro;
- formalizar contexto local;
- decidir regras por fluxo;
- usar SQL como motor.

---

## 4. Decisões consolidadas

1. Estoque é ledger, não número editável.
2. Contagem física gera delta.
3. `meta_estoque` é meta física da Loja.
4. Loja e CD são contextos independentes do mesmo insumo.
5. Categoria deve definir política padrão de contagem.
6. Insumo/local pode sobrescrever a política da categoria.
7. Compra, reposição e produção são motores distintos.
8. Retool deve ter menos regra de negócio.

---

## 5. Dívidas técnicas conhecidas

- `destino_abastecimento` e `modelo_reposicao` ainda existem.
- `setores[]` exerce responsabilidades demais.
- categorias são vinculadas por texto em consultas.
- `contagem_diaria` e `dias_contagem` precisam ser reconciliados.
- o dump analisado não mostra `dias_contagem`, embora o CSV de categorias já possua esse campo.
- `criar_reposicao_por_contagem` contém lógica antiga.
- `getInsumosContagemCD` não considera produzidos internamente.
- `getPainelCompras` depende de view ausente no dump.

---

## 6. Artefatos usados nesta fotografia

- `Painel-Operacional(2).zip`
- `public-2026-09-06_201044-dump.sql`
- `categorias_rows (1).csv`
- documentação Saipos fornecida anteriormente
- decisões consolidadas na análise de 06/09/2026–07/09/2026
