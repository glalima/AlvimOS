# ALVIM OS — CURRENT STATE

**Data:** 09/09/2026  
**Objetivo:** permitir retomar o projeto sem reanalisar toda a arquitetura e separar claramente o que está funcionando, o que está sendo estabilizado e o que será refatorado.

---

## 1. Decisão arquitetural mais recente

O modelo está evoluindo de **4 chaves logísticas** para:

### 3 características logísticas globais
- `produzido_internamente`
- `recebido_no_cd`
- `enviado_loja`

### + políticas de estoque por local
- política de contagem;
- classificação/categoria por local;
- parâmetros de volume quando aplicáveis;
- metas por dia quando aplicáveis na Loja.

`compra_diaria` passa a ser considerada **DEPRECATED / candidata à remoção**, mas **não deve ser removida ainda**.

O ADR-006 está em estado **PROPOSTO** até concluir a varredura de dependências e validar os casos reais.

---

## 2. Regras operacionais consolidadas

### CD
O estoque do CD é sempre controlado por **volume** quando necessita recomposição:

`saldo_cd <= estoque_gatilho → recompor até estoque_ideal`

Quando o item é recebido externamente no CD, essa necessidade normalmente gera compra.

### Loja
A Loja pode trabalhar de duas formas:

#### VOLUME
Exemplo: Coca-Cola 2L.

Usa:
- estoque gatilho;
- estoque ideal;
- política de contagem própria.

Não possui obrigação de ter metas segunda–domingo.

#### META_DIA
Exemplo: Tampa 550 ml.

Usa:
- metas físicas por dia da semana;
- política de contagem própria.

A meta representa o alvo operacional físico da Loja, não o alvo de compra do CD.

### Política de contagem
É independente da forma de recomposição.

A mesma mercadoria pode ser contada em frequências diferentes na Loja e no CD.

Modelo de herança aprovado:

`categoria/local → padrão`
`insumo/local → override opcional`

---

## 3. Estado técnico atual do cadastro de insumos

### Problemas verificados no export analisado

`backend/insumos/getInsumosCatalog.ts` não retorna:
- `gatilho_pedido`
- `recebido_no_cd`
- `enviado_loja`
- `compra_diaria`
- metas existentes.

Consequência:
o formulário de edição pode carregar defaults em vez do estado real.

`createInsumo.ts` e `updateInsumo.ts` ainda possuem regra antiga:

`requiresVolume = !compra_diaria && !produzido_internamente`

Essa regra conflita com o modelo atual, pois itens recebidos no CD podem precisar de gatilho/ideal independentemente de `compra_diaria`.

### Metas

`createInsumo.ts` cria uma linha em `meta_estoque` para todo item com `enviado_loja = true`, mesmo quando o item deveria operar por volume na Loja.

`updateInsumo.ts` atualiza metas existentes, mas não garante criação quando a linha está ausente.

O formulário atual só exibe metas quando `compra_diaria = true`.

### Classificação

O modelo atual ainda usa:
- `categoria`
- `categoria_loja`
- `categoria_cd`
- `setores[]`

Existe trigger que espelha `categoria_loja → categoria` e tenta preencher `setores`.

Esse modelo será substituído gradualmente por contexto de estoque por local.

---

## 4. Estado técnico atual das contagens

### Loja
A contagem usa:
- `enviado_loja = true`;
- `categoria_loja`;
- `setores[]`;
- `saldo_loja` da `vw_estoque_master`;
- `categorias.contagem_diaria`.

### CD
A contagem usa:
- `recebido_no_cd = true`;
- `categoria_cd`;
- `saldo_cd` da `vw_estoque_master`;
- `categorias.contagem_diaria`.

### Gap confirmado
A contagem do CD ainda não inclui automaticamente:

`produzido_internamente = true AND recebido_no_cd = false`

mesmo quando o item produzido existe fisicamente no CD.

### Política de dias
O CSV atual de categorias já possui `dias_contagem`, porém o dump analisado ainda não contém essa coluna.

Antes de criar migration, confirmar qual é o schema real mais recente no Supabase.

---

## 5. Dependências atuais de `compra_diaria` encontradas

No export analisado, `compra_diaria` aparece em:

### Banco
- coluna `insumos.compra_diaria`;
- `vw_estoque_master`.

### Backend
- `createInsumo.ts`;
- `updateInsumo.ts`;
- tipagem de `getPainelCompras.ts`.

### Frontend
- `InsumoFormDialog.tsx`;
- `NewInsumoDialog.tsx`;
- tipagem de `PainelCompras.tsx`.

Não foi encontrada dependência direta de `compra_diaria` nas queries atuais de contagem Loja/CD.

**Status da varredura:** PARCIAL — ainda precisa confirmar o banco vivo e queries/objetos atuais do Retool antes de remover a coluna.

---

## 6. Ordem de execução aprovada

### CHANGE-001A — Estabilizar cadastro atual
**Status:** PRÓXIMO PASSO

Objetivo:
corrigir bugs de leitura/salvamento sem fazer ainda a migração estrutural completa.

Fazer:
1. leitura completa e confiável do cadastro;
2. carregar metas existentes;
3. impedir sobrescrita por defaults;
4. corrigir Salvar;
5. corrigir Salvar + Próximo;
6. corrigir Salvar + Anterior;
7. não criar novas dependências de `compra_diaria`;
8. evitar aprofundar lógica que será substituída pelo contexto por local.

### ADR-006 / varredura
**Status:** EM VALIDAÇÃO

Antes da primeira migration estrutural:
- concluir dependências de `compra_diaria`;
- confirmar schema real de `categorias.dias_contagem`;
- validar Coca 2L, Tampa 550, Tomate e item direto à Loja.

### CHANGE-002A — Contexto por local + migração
**Status:** PLANEJADO

Criar nova estrutura em coexistência com a antiga.

Não remover campos legados nesta etapa.

### CHANGE-002B — Contagem Loja/CD por contexto
**Status:** PLANEJADO

Criar uma fonte SQL comum para as duas contagens:
- contexto;
- categoria;
- setor;
- saldo;
- política de dias;
- `deve_contar_hoje`.

### CHANGE-003 — Painel de Compras
**Status:** POSTERIOR

Só reconstruir depois do contexto por local estar validado.

---

## 7. Casos obrigatórios de validação

### Coca-Cola 2L
- existe/controlada na Loja;
- pode existir no CD;
- Loja opera por volume;
- sem metas diárias obrigatórias;
- contagem pode ser semanal.

### Tampa 550 ml
- CD opera por volume;
- Loja opera por metas do dia;
- categorias podem ser diferentes por local;
- frequência de contagem pode ser diferente por local.

### Tomate inteiro
- recebido no CD;
- pode não existir na Loja;
- matéria-prima de transformação interna.

### Entrega direta à Loja
- `recebido_no_cd = false`;
- `enviado_loja = true`;
- contexto Loja válido sem exigir contexto CD.

### Produzido internamente
- pode existir no CD mesmo com `recebido_no_cd = false`.

---

## 8. Próxima ação concreta

**Não criar migration de contexto ainda.**

Primeiro concluir o `CHANGE-001A` de estabilização do cadastro e finalizar a fotografia das dependências atuais.

Durante esse trabalho:
- manter schema atual;
- não remover `compra_diaria`;
- não remover categorias/setores legados;
- evitar implementar regras novas no frontend;
- registrar cada SQL estrutural futuro como migration no GitHub.

---

## 9. Fonte desta fotografia

- documentação AlvimOS v2.0;
- ADR-006 proposto;
- `Painel-Operacional(2).zip` exportado em 06/09/2026;
- `public-2026-09-06_201044-dump.sql`;
- `categorias_rows (1).csv`;
- decisões operacionais consolidadas até 09/09/2026.

**Importante:** antes de executar migrations estruturais, confirmar diferenças entre o dump de 06/09 e o banco vivo atual.
