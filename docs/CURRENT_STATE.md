# ALVIM OS — CURRENT STATE

**Data:** 12/09/2026
**Objetivo:** registrar somente o estado operacional e arquitetural atual do projeto.

---

## 1. Arquitetura atual

O ADR-006 está **ACEITO**.

O modelo atual separa:

###### Características globais do insumo

- `produzido_internamente`
- `recebido_no_cd` — nome físico legado; semanticamente `recebido_externamente_no_cd`
- `enviado_loja` — nome físico legado; semanticamente `controlado_na_loja`

`compra_diaria` está **DEPRECATED** e não deve ser usada em novas regras.

### Contexto físico de estoque

Tabela:

`insumo_contexto_estoque`

Regra:

```text
CONTEXTO CD
= produzido_internamente
  OR recebido_no_cd

CONTEXTO LOJA
= enviado_loja
```

O contexto define onde o saldo do insumo é controlado.

---

## 2. Política por categoria

Cada categoria pertence a um local operacional, representado atualmente por:

`categorias.tipo = LOJA | CD`

A categoria é a fonte do comportamento padrão.

Campos adicionados:

- `modo_reposicao_padrao`
- `dias_contagem_padrao`
- `ativo_contagem`

A política efetiva é:

`override do contexto ?? padrão da categoria`

O contexto do insumo deve armazenar apenas exceções.

A resolução efetiva já está materializada em:

`vw_contexto_estoque_efetivo`

---

## 3. Reposição

### CD

Sempre por `VOLUME`.

Usa:

- `estoque_gatilho`
- `estoque_ideal`

### Loja

Pode operar por:

- `VOLUME`
- `META_DIA`

A política padrão é herdada da categoria.

---

## 4. Contagem

A política de contagem é independente da política de reposição.

A categoria define:

`dias_contagem_padrao`

O insumo/contexto pode definir:

`dias_contagem_override`

Regra efetiva:

`dias efetivos = override ?? padrão da categoria`

A fonte SQL comum das contagens Loja/CD já foi criada:

`vw_contagem_estoque`

Ela combina contexto, categoria, setor, saldo do local, dias efetivos de contagem, `deve_contar_hoje`, meta do dia quando aplicável, gatilho e estoque ideal.

A view foi validada sem duplicidade por `(insumo_id, local)`, sem inconsistência categoria/local, sem ausência de saldo e sem metas ausentes nos contextos `META_DIA`.

As telas/consumidores atuais ainda não foram migrados integralmente para essa fonte.

---

## 5. CHANGE-001A

**Status: CONCLUÍDO**

Cadastro atual estabilizado.

Validado:

- carregamento de dados;
- criação;
- edição;
- Salvar;
- Salvar + Próximo;
- Salvar + Anterior;
- persistência PostgreSQL/Supabase.

---

## 6. CHANGE-002A

### Fase B6 — CONCLUÍDA

Migradas as metas válidas do modelo legado para `meta_estoque_contexto`.

Resultado:

- 145 contextos LOJA com política efetiva `META_DIA`;
- 1.015 metas normalizadas;
- 7 dias por contexto;
- 0 metas migradas para contextos `VOLUME`.

As metas históricas dos 182 itens `VOLUME` permanecem em `meta_estoque` apenas como legado temporário e não possuem significado operacional no novo modelo.

O item MORANGO permanece com meta 0 nos sete dias, conforme configuração histórica.

Também estão implementados e validados:

- `insumo_contexto_estoque`;
- `meta_estoque_contexto`;
- políticas padrão por categoria;
- mapeamentos de categoria por local;
- herança efetiva de política;
- `vw_contexto_estoque_efetivo`.

---

## 7. CHANGE-002B

**Status: EM ANDAMENTO / PAUSADA PARA ESTABILIZAÇÃO DE COMPRAS**

A fonte SQL comum das contagens Loja/CD foi criada e validada:

`vw_contagem_estoque`

Validação registrada:

- 464 contextos no total;
- 327 contextos LOJA;
- 137 contextos CD;
- sem duplicidade `(insumo_id, local)`;
- sem incompatibilidade categoria/local;
- sem ausência de saldo;
- sem ausência de meta para contexto `META_DIA`.

A próxima etapa da CHANGE-002B é migrar os consumidores/telas de contagem para essa fonte.

Essa migração está temporariamente pausada enquanto a entrada de compras é estabilizada na CHANGE-001B.

---

## 8. CHANGE-001B — Entrada de compras

**Status: EM ANDAMENTO — PRIORIDADE ATUAL**

Objetivo: estabilizar o fluxo entre a ingestão da nota fiscal, conciliação dos itens e entrada física no ledger.

Fluxo atual:

```text
Google Drive
→ n8n
→ Gemini
→ Code JS
→ fornecedores / compras / compra_itens
→ StockReconciliation
→ de_para_insumos + fator_conversao
→ finalizar_entrada_compra()
→ movimentacoes_estoque
→ vw_estoque_master
```

### Estado validado

O fluxo ponta a ponta foi testado com sucesso:

`NF → importação → conciliação → de-para → RPC → ENTRADA_COMPRA → saldo`

A RPC `finalizar_entrada_compra(uuid)`:

- bloqueia a compra durante a finalização;
- impede nova entrada quando a compra já está concluída;
- exige que todos os itens estejam mapeados;
- grava `ENTRADA_COMPRA`;
- atualiza `status_estoque` para `CONCLUIDO`.

A idempotência da RPC foi testada e validada.

### Gap P0 confirmado

A ingestão atual do n8n ainda não é idempotente para os itens da compra.

Ao reenviar uma NF com a mesma `chave_acesso`:

- a compra existente é reutilizada;
- `compra_itens` é inserido novamente.

Portanto, a mesma nota pode acumular linhas duplicadas mesmo sem duplicar a linha de `compras`.

A correção da idempotência da ingestão n8n é o próximo passo imediato da CHANGE-001B.

### Pendências posteriores da CHANGE-001B

Após a idempotência da ingestão:

- determinar corretamente `CD` ou `LOJA` como local físico da entrada;
- tratar múltiplas linhas da mesma compra mapeadas para o mesmo insumo;
- normalizar `custo_unitario` pelo `fator_conversao`;
- impedir que itens `produzido_internamente=true` apareçam como opção normal de conciliação de compra.

A CHANGE-001B **não deve ser considerada concluída** antes dessas validações.

---

## 9. Dívidas e legado ainda existentes

Ainda permanecem fisicamente:

- `compra_diaria`;
- `recebido_no_cd`;
- `enviado_loja`;
- `categoria_loja`;
- `categoria_cd`;
- `setores`;
- `meta_estoque`.

Eles não devem ser removidos antes da migração completa dos consumidores.

As metas válidas dos contextos LOJA com política `META_DIA` já foram migradas para `meta_estoque_contexto`.

As metas históricas dos itens `VOLUME` permanecem em `meta_estoque` apenas como legado temporário.

Os contextos e as novas views já existem, mas ainda não são a fonte oficial de todos os consumidores/telas atuais.

---

## 10. Ordem macro

```text
CHANGE-001A ✅
→ CHANGE-002A
   A  ✅
   B2 ✅
   B3 ✅
   B4 ✅
   B5 ✅
   B6 ✅

→ CHANGE-002B
   fonte SQL de contagem ✅
   migração dos consumidores ⏸

→ CHANGE-001B
   estabilização da entrada de compras 🔄 PRIORIDADE ATUAL

→ retomar CHANGE-002B
→ CHANGE-003
```

Prioridade:

```text
CONSISTÊNCIA
→ AUDITABILIDADE
→ AUTOMAÇÃO
→ INTELIGÊNCIA
→ ESCALA
```

---

## 11. Próximo passo imediato

Corrigir a idempotência da ingestão de notas no n8n.

Regra alvo:

- NF nova → cria `compras` e `compra_itens`;
- NF já existente → não duplica `compra_itens`;
- NF concluída → não altera a compra e não gera nova movimentação;
- `chave_acesso` permanece como identidade principal da nota fiscal.

Para alterar com segurança o node PostgreSQL do n8n, deve-se primeiro analisar o SQL/template atualmente executado pelo node, sem presumir a sintaxe das expressões do workflow.

Depois dessa correção, continuar as demais pendências da CHANGE-001B.
