# ALVIM DELIVERY — MAPA TÉCNICO MASTER v2.0

**Data-base:** 06/09/2026  
**Status:** documento de navegação arquitetural  
**Regra:** detalhes devem viver nos documentos de domínio e ADRs.

---

## 1. Produto

ALVIM OS é a evolução do Painel Operacional do Alvim Delivery para uma camada central de operação.

Cadeia operacional:

`PEDIDOS → CONSUMO → ESTOQUE → CONTAGEM → NECESSIDADE → REPOSIÇÃO → PRODUÇÃO → COMPRAS → FINANCEIRO → ANALYTICS`

Cadeia cliente:

`CLIENTES → PEDIDOS → RFV → CRM → CAMPANHAS → RETENÇÃO → LTV`

---

## 2. Stack

### Frontend
React + TypeScript + Vite + Retool.

### Backend
Funções TypeScript por domínio.

### Banco
PostgreSQL/Supabase.

### Direção arquitetural
Migrar lógica determinística e transacional do Retool/TypeScript para:
- views;
- funções/RPCs;
- constraints;
- transações;
- migrations.

---

## 3. Domínios

1. Identidade e Acesso
2. Insumos
3. Estoque/Ledger
4. Contagem
5. Reposição
6. CD
7. Produção
8. Compras
9. Financeiro
10. Pedidos
11. Clientes
12. CRM
13. Integrações
14. Analytics
15. Auditoria

---

## 4. Cadastro de insumos

Tabela atual:
`insumos`

Campos logísticos principais:
- `produzido_internamente`
- `recebido_no_cd`
- `enviado_loja`
- `compra_diaria`
- `estoque_minimo`
- `gatilho_pedido`
- `estoque_ideal`

Campos de classificação atuais:
- `categoria`
- `categoria_loja`
- `categoria_cd`
- `setores[]`

**Estado:** esses campos de classificação são considerados modelo transitório.

**Alvo:** contexto por local.

---

## 5. Contexto por local

Modelo aprovado:

`INSUMO → LOCAL → SETOR → CATEGORIA → POLÍTICA DE CONTAGEM`

Um mesmo insumo pode possuir:
- contexto Loja;
- contexto CD;
- ambos.

Exemplo:
Tampa 550:
- Loja → Açaí → 8 - Embalagens - Açaí
- CD → CD → Embalagens

---

## 6. Metas da Loja

Tabela:
`meta_estoque`

Semântica oficial:
**meta física da Loja por dia da semana**.

Fórmula de necessidade:
`MAX(meta_dia - saldo_loja, 0)`

A meta não substitui:
- estoque ideal;
- gatilho;
- política de compra do CD.

---

## 7. Ledger

Tabela:
`movimentacoes_estoque`

View:
`vw_estoque_master`

Saldos calculados:
- Loja
- CD
- Total

Princípio:
**não atualizar saldo diretamente.**

---

## 8. Contagem

RPC moderna:
`registrar_contagem_estoque`

Fórmula:
`delta = físico - sistema`

Ajustes:
- positivo → `AJUSTE_ENTRADA`
- negativo → `AJUSTE_SAIDA`

Alvo de evolução:
uma view única de itens de contagem com parâmetro/contexto local.

---

## 9. Política de contagem

Categorias já possuem no CSV operacional:
- `contagem_diaria`
- `dias_contagem`

O dump analisado ainda não contém `dias_contagem`.

Modelo alvo:

**Categoria/local define padrão → insumo/local pode sobrescrever.**

A política da Loja não deve ser automaticamente igual à do CD.

---

## 10. Reposição

Fluxo:

`CONTAGEM LOJA → META LOJA → NECESSIDADE → PENDENTE_CD → ENVIO → RECEBIMENTO → LEDGER`

Regras de reposição devem ser independentes da política de compra do fornecedor.

---

## 11. Produção

O CD é também unidade de transformação.

Exemplo:

`TOMATE INTEIRO → CD → PROCESSAMENTO → RODELAS / PICADO`

Futuro:
- ordens de produção;
- consumo de matéria-prima;
- rendimento;
- perdas;
- entrada de produzido;
- necessidade produtiva.

---

## 12. Compras

Backend atual:
`backend/reposicoes/getPainelCompras.ts`

Dependência atual:
`view_painel_compras`

**Gap:** view não aparece no dump analisado.

Direção:
motor 100% SQL, usando:
- contexto de abastecimento;
- saldo relevante;
- gatilho;
- estoque ideal;
- fornecedor;
- histórico.

---

## 13. Compras × Reposição

Não confundir:

### Compra
traz estoque de fora da empresa.

### Reposição
move estoque existente internamente.

Exemplo Tampa:
- fornecedor → CD: compra por volume;
- CD → Loja: reposição pela meta física da Loja.

---

## 14. Financeiro

Compras separam:
- status físico/estoque;
- status financeiro.

A função `finalizar_entrada_compra` já lança `ENTRADA_COMPRA`.

---

## 15. Integrações

Saipos:
- API de Dados;
- vendas;
- estoque/movimentações;
- futuro consumo automático.

Piloto sugerido:
categoria simples como cigarros.

Princípios:
- staging;
- de-para;
- idempotência;
- `updated_at`;
- modo simulação antes de afetar ledger.

---

## 16. CRM

Já existem estruturas de clientes/pedidos e views CRM.

CRM permanece domínio separado da cadeia operacional, com integração futura por vendas.

---

## 17. Acesso

Frontend possui papéis como:
- DEV
- ADMIN
- CD
- LOJA

Gap:
segurança não deve depender apenas do bloqueio visual.

---

## 18. Padrão para alterações

Toda alteração relevante deve registrar:

- TÍTULO
- DOMÍNIO
- PROBLEMA
- ESTADO ATUAL
- ESTADO ALVO
- GAP
- REGRAS
- BANCO
- BACKEND
- FRONTEND
- RISCOS
- MIGRATION
- TESTES
- CRITÉRIOS DE ACEITE
- STATUS

---

## 19. Prioridade

1. Cadastro de insumos
2. Contexto por local
3. Contagem Loja + CD
4. Reposição
5. Painel de Compras
6. Produção
7. Integração Saipos
8. Analytics/Inteligência

---

## 20. Documentos relacionados

- `00_START_HERE.md`
- `CURRENT_STATE.md`
- `/02_DOMINIOS/*`
- `/03_ADR/*`
- `/04_CHANGES/*`
