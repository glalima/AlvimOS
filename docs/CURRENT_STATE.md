# ALVIM OS — CURRENT STATE

**Data:** 09/09/2026
**Objetivo:** registrar somente o estado operacional e arquitetural atual do projeto.

---

## 1. Arquitetura atual

O ADR-006 está **ACEITO**.

O modelo atual separa:

### Características globais do insumo

- `produzido_internamente`
- `recebido_no_cd` — nome físico legado; semanticamente `recebido_externamente_no_cd`
- `enviado_loja` — nome físico legado; semanticamente `controlado_na_loja`

`compra_diaria` está **DEPRECATED** e não deve ser usada em novas regras.

### Contexto físico de estoque

Tabela:

`insumo_contexto_estoque`

Regra:

CONTEXTO CD
= produzido_internamente
  OR recebido_no_cd

CONTEXTO LOJA
= enviado_loja

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

A política efetiva futura será:

`override do contexto ?? padrão da categoria`

O contexto do insumo deverá armazenar apenas exceções.

---

## 3. Reposição

### CD

Sempre por `VOLUME`.

Usa:

- estoque_gatilho
- estoque_ideal

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

O insumo/contexto poderá definir:

`dias_contagem_override`

Objetivo futuro das telas:

`dias efetivos = override ?? padrão da categoria`

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

**Status: EM IMPLEMENTAÇÃO**

### Fase A — CONCLUÍDA

Criadas:

- `insumo_contexto_estoque`
- `meta_estoque_contexto`

### Fase B2 — CONCLUÍDA

Criados:

- 140 contextos CD;
- 327 contextos LOJA.

Validações:

- esperado CD = criado CD;
- esperado Loja = criado Loja;
- nenhum contexto sem categoria na primeira migração;
- todos permanecem `ativo = false`.

`gatilho/ideal = 0/0` é permitido temporariamente e representa parametrização ainda não definida.

### Fase B3 — CONCLUÍDA

A tabela `categorias` agora possui:

- `modo_reposicao_padrao`;
- `dias_contagem_padrao`;
- `ativo_contagem`.

Regras:

- CD = sempre `VOLUME`;
- Loja = `VOLUME` ou `META_DIA`;
- categoria define default;
- contexto define override.

Criada categoria específica `CIGARROS / CD`.

---

## 7. Dívidas e legado ainda existentes

Ainda permanecem fisicamente:

- `compra_diaria`;
- `recebido_no_cd`;
- `enviado_loja`;
- `categoria_loja`;
- `categoria_cd`;
- `setores`;
- `meta_estoque`.

Eles não devem ser removidos antes da migração completa dos consumidores.

Metas históricas ainda não foram migradas para `meta_estoque_contexto`.

Os contextos ainda não são a fonte oficial das telas atuais.

---

## 8. Próximo passo

### CHANGE-002A — próxima fase

Auditar e corrigir `categoria_id` dos contextos para garantir:

- contexto `CD` → categoria `tipo = 'CD'`;
- contexto `LOJA` → categoria `tipo = 'LOJA'`.

Depois:

1. implementar herança efetiva de política;
2. migrar metas válidas para `meta_estoque_contexto`;
3. preparar views SQL de contagem;
4. migrar as duas telas de contagem;
5. somente depois reconstruir o Painel de Compras.

---

## 9. Ordem macro

CHANGE-001A ✅
→ CHANGE-002A 🔄
→ CHANGE-002B
→ CHANGE-003

Prioridade:

CONSISTÊNCIA
→ AUDITABILIDADE
→ AUTOMAÇÃO
→ INTELIGÊNCIA
→ ESCALA
