# ALVIM OS — START HERE

**Versão da documentação:** 2.0  
**Data-base analisada:** 06/09/2026  
**Projeto:** Painel Operacional / ALVIM OS  
**Objetivo:** fornecer contexto mínimo, confiável e navegável para IA, desenvolvimento, manutenção e evolução.

---

## 1. Regra de ouro

Este arquivo é a porta de entrada do projeto.

Antes de alterar código ou banco:

1. Leia este documento.
2. Identifique o domínio afetado em `/02_DOMINIOS`.
3. Consulte os ADRs relacionados em `/03_ADR`.
4. Consulte o CHANGE ativo em `/04_CHANGES`.
5. Só então compare **estado atual × estado alvo × código × banco**.

Nenhuma IA deve assumir que uma regra existente no código está correta apenas porque está implementada.

---

## 2. Visão em uma frase

O **ALVIM OS** é a camada operacional que pretende conectar:

`VENDA → CONSUMO → ESTOQUE → CONTAGEM → NECESSIDADE → REPOSIÇÃO → PRODUÇÃO → COMPRA → RECEBIMENTO → FINANCEIRO → INDICADORES → DECISÃO`

e, paralelamente:

`CLIENTE → PEDIDO → COMPORTAMENTO → CRM → CAMPANHA → RETENÇÃO → LTV`

---

## 3. Arquitetura tecnológica atual

### Frontend
- React 19
- TypeScript
- Vite
- React Router
- Tailwind CSS
- Radix UI
- Recharts
- TanStack React Table
- ambiente Retool

### Backend
Funções TypeScript por domínio:

- `/backend/home`
- `/backend/insumos`
- `/backend/inventory`
- `/backend/purchases`
- `/backend/reposicoes`

### Banco
- PostgreSQL / Supabase
- Resource operacional utilizado pelo projeto via Retool

### Princípio arquitetural desejado

**PostgreSQL = fonte principal de regras, cálculos, integridade e transações.**  
**Backend TypeScript = camada fina de entrada/saída.**  
**React/Retool = interface, navegação, filtros e experiência do usuário.**

---

## 4. Princípios de evolução

Ordem de prioridade:

1. **Consistência**
2. **Auditabilidade**
3. **Automação**
4. **Inteligência**
5. **Escala**

Evitar:
- regras de negócio duplicadas entre React, TypeScript e SQL;
- alterações diretas de saldo sem ledger;
- migrations sem documentação;
- usar campos legados para novas funcionalidades;
- misturar estado atual com arquitetura futura.

---

## 5. As 4 chaves logísticas

Tabela principal atual: `insumos`.

### `produzido_internamente`
Indica que o item é produzido/transformado internamente.

### `recebido_no_cd`
Indica que o item entra fisicamente no estoque do CD.

### `enviado_loja`
Indica que o item existe/é controlado no contexto da Loja.

**Importante:** não significa necessariamente que o item veio do CD. Um fornecedor pode entregar diretamente na Loja.

### `compra_diaria`
Chave operacional ainda em refinamento semântico.

Ela **não deve ser interpretada isoladamente como "usar meta diária para compra"**, porque existem casos, como embalagens recebidas no CD, em que:
- `recebido_no_cd = true`
- `enviado_loja = true`
- `compra_diaria = true`
- o CD continua sendo comprado por **gatilho + estoque ideal**
- a Loja continua sendo abastecida por **meta física diária**

Consultar `ADR-002`, `ADR-003` e `ADR-004`.

---

## 6. Conceito fundamental: o insumo pode existir em mais de um contexto físico

Exemplo: **Tampa 550 ml**.

Na Loja:
- setor: Açaí
- categoria: `8 - Embalagens - Açaí`
- política de contagem própria da Loja

No CD:
- setor/local: CD
- categoria: Embalagens
- política de contagem própria do CD

Portanto, a classificação correta é conceitualmente:

`INSUMO → LOCAL → SETOR → CATEGORIA → POLÍTICA DE CONTAGEM`

O modelo atual ainda representa parte disso por:
- `categoria`
- `categoria_loja`
- `categoria_cd`
- `setores[]`

Essa estrutura é considerada dívida técnica e está em processo de refatoração para **contexto por local**.

---

## 7. Estoque e ledger

Tabela central:
`movimentacoes_estoque`

View central atual:
`vw_estoque_master`

Saldos:
- `saldo_loja`
- `saldo_cd`
- `saldo_total`

Tipos atualmente reconhecidos pela view:
- `ENTRADA_COMPRA`
- `ENTRADA_TRANSFERENCIA`
- `AJUSTE_ENTRADA`
- `SAIDA_CONSUMO`
- `SAIDA_TRANSFERENCIA`
- `AJUSTE_SAIDA`

A contagem física não deve ser gravada como saldo absoluto. A RPC `registrar_contagem_estoque(...)` calcula:

`delta = quantidade_fisica - saldo_sistema`

e grava somente `AJUSTE_ENTRADA` ou `AJUSTE_SAIDA`.

---

## 8. Meta de estoque

`meta_estoque` representa o **alvo físico da Loja por dia da semana**.

Não representa:
- estoque ideal do CD;
- gatilho de compra;
- estoque alvo geral da empresa.

Uso principal:

`necessidade_loja = MAX(meta_dia - saldo_loja, 0)`

O fornecedor/CD que atende essa necessidade depende do fluxo logístico.

---

## 9. Três motores operacionais

### Motor de Compras
Pergunta: **o que precisa entrar de fora da empresa?**

### Motor de Reposição
Pergunta: **o que já existe internamente e precisa ser deslocado para a Loja?**

### Motor de Produção
Pergunta: **o que precisa ser transformado no CD para atender a operação?**

Esses motores não devem compartilhar fórmulas apenas por conveniência.

---

## 10. Estado atual verificado no código/dump de 06/09/2026

### Já existe
- `vw_estoque_master`
- `registrar_contagem_estoque`
- `confirmar_envio_cd`
- `confirmar_recebimento_loja`
- `finalizar_entrada_compra`
- quatro chaves booleanas na tabela `insumos`

### Gaps confirmados
1. `backend/insumos/getInsumosCatalog.ts` não retorna:
   - `recebido_no_cd`
   - `enviado_loja`
   - `compra_diaria`
   - `gatilho_pedido`

2. A tela pode abrir chaves usando defaults e salvar valores diferentes dos existentes no banco.

3. As metas existentes não são carregadas corretamente no formulário de edição.

4. `createInsumo.ts` e `updateInsumo.ts` duplicam regras de negócio.

5. `updateInsumo.ts` usa `UPDATE meta_estoque`; se a linha não existir, pode ocorrer falha silenciosa.

6. `getInsumosContagemCD.ts` filtra apenas `recebido_no_cd = true`, apesar de itens `produzido_internamente = true` também poderem existir no CD.

7. `getPainelCompras.ts` chama `view_painel_compras`, porém essa view não aparece no dump analisado.

8. Existe função antiga `criar_reposicao_por_contagem(...)` usando:
   - `AJUSTE_CONTAGEM`
   - referência a `guardiao_estoque_metas`

   Isso conflita com o ledger/estrutura atual e deve ser tratado como legado até validação.

9. Campos legados continuam na tabela `insumos`:
   - `destino_abastecimento`
   - `modelo_reposicao`

---

## 11. Prioridades atuais

### P0
- estabilizar cadastro/edição de insumos;
- criar leitura única e confiável do cadastro;
- reduzir regra de negócio no Retool/TypeScript;
- formalizar contexto de estoque por local;
- melhorar **as duas contagens**: Loja e CD;
- implementar política de contagem por local/categoria/insumo.

### P1
- reconstruir `view_painel_compras`;
- formalizar regra de saldo relevante por fluxo logístico;
- validar compras com insumos reais.

### P2
- integração Saipos, começando por piloto simples como cigarros;
- consumo automático no ledger;
- produção interna estruturada.

---

## 12. O que ler por tarefa

| Tarefa | Ler |
|---|---|
| Cadastro de insumo | `02_DOMINIOS/INSUMOS.md` + `CHANGE-001` |
| Contagem Loja/CD | `02_DOMINIOS/CONTAGEM.md` + `ADR-004` + `ADR-005` |
| Ledger | `02_DOMINIOS/ESTOQUE_LEDGER.md` + `ADR-001` |
| Reposição | `02_DOMINIOS/REPOSICAO.md` + `ADR-003` |
| Painel de Compras | `02_DOMINIOS/COMPRAS.md` + `CHANGE-003` |
| Produção | `02_DOMINIOS/PRODUCAO.md` |
| Saipos | `02_DOMINIOS/INTEGRACOES.md` |
| Estado do trabalho | `CURRENT_STATE.md` |

---

## 13. Regra para IA

Antes de escrever código:

**ENTENDER → IDENTIFICAR DOMÍNIO → LER ADR → INSPECIONAR BANCO → INSPECIONAR CÓDIGO → COMPARAR ATUAL × ALVO → PROPOR CHANGE → IMPLEMENTAR → TESTAR → DOCUMENTAR**

Sempre declarar quando algo é:
- **VERIFICADO**
- **DECISÃO APROVADA**
- **HIPÓTESE**
- **PENDENTE DE DEFINIÇÃO**
