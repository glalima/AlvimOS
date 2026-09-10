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
### Fase B6 — CONCLUÍDA

Migradas as metas válidas do modelo legado para `meta_estoque_contexto`.

Resultado:
- 145 contextos LOJA com política efetiva `META_DIA`;
- 1.015 metas normalizadas;
- 7 dias por contexto;
- 0 metas migradas para contextos `VOLUME`.

As metas históricas dos 182 itens `VOLUME` permanecem em `meta_estoque`
apenas como legado temporário e não possuem significado operacional no novo modelo.

O item MORANGO permanece com meta 0 nos sete dias, conforme configuração histórica.

### Próximo passo

Criar a fonte SQL comum das contagens Loja/CD usando:
- contexto;
- categoria;
- setor;
- saldo do local;
- dias efetivos de contagem;
- `deve_contar_hoje`;
- meta do dia quando aplicável.

Depois migrar as telas de contagem para consumir essa fonte.

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
