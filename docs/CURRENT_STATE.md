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

### Fase B5 — CONCLUÍDA

Implementada a herança efetiva das políticas operacionais por contexto.

Criada:
- `vw_contexto_estoque_efetivo`

Regra oficial:

`política efetiva = override do contexto ?? padrão da categoria`

Para o CD:
- política efetiva sempre `VOLUME`.

Para contagem:

`dias efetivos = dias_contagem_override ?? dias_contagem_padrao`

Também foi ajustada a semântica do contexto:
- `modo_reposicao_loja` → `modo_reposicao_override`;
- o contexto passa a armazenar somente exceções;
- a categoria é a fonte do comportamento padrão.

Validação concluída:
- nenhum contexto sem política efetiva;
- nenhum contexto ativo para contagem sem dias efetivos;
- nenhum contexto CD fora de `VOLUME`;
- contextos LOJA herdando corretamente `VOLUME` ou `META_DIA` de suas categorias.

Os consumidores atuais ainda não foram migrados para a nova view.

### Próximo passo

Migrar as metas históricas válidas para `meta_estoque_contexto`.

Somente contextos:
- `local = 'LOJA'`;
- `modo_reposicao_efetivo = 'META_DIA'`

podem receber metas no novo modelo.

Metas históricas de itens cuja política atual é `VOLUME` não devem ser consideradas automaticamente válidas..

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

## 9. Ordem macro

CHANGE-001A ✅
→ CHANGE-002A
   A  ✅
   B2 ✅
   B3 ✅
   B4 ✅
   B5 ✅
   próxima: migração das metas
→ CHANGE-002B
→ CHANGE-003
Prioridade:

CONSISTÊNCIA
→ AUDITABILIDADE
→ AUTOMAÇÃO
→ INTELIGÊNCIA
→ ESCALA
