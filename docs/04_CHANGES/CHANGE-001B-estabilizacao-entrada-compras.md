# CHANGE-001B — Estabilização da entrada de compras

**Status:** EM ANDAMENTO  
**Data:** 12/09/2026  
**Domínio:** Compras / Recebimento / Estoque  
**Prioridade:** P0

---

## 1. Objetivo

Estabilizar o fluxo completo de entrada de compras, desde a ingestão da nota fiscal até a geração da movimentação no ledger de estoque.

Fluxo real observado:

`Google Drive → n8n → Gemini → normalização JS → fornecedores/compras/compra_itens → Retool StockReconciliation → de-para + fator de conversão → finalizar_entrada_compra() → movimentacoes_estoque → vw_estoque_master`

A CHANGE só pode ser concluída quando esse caminho for seguro, auditável e idempotente.

---

## 2. Estado atual verificado

### 2.1 Ingestão da nota — n8n

Workflow atual:

1. Google Drive Trigger observa a pasta de notas;
2. arquivo é baixado;
3. Gemini extrai dados estruturados da NF;
4. Code node em JavaScript normaliza e valida os dados;
5. node PostgreSQL grava `fornecedores`, `compras` e `compra_itens`.

A automação usa `chave_acesso` para impedir a criação de uma segunda linha em `compras` para a mesma NF.

### 2.2 Conciliação — Retool

Tela:

`StockReconciliation`

Backend verificado:

- `getPendingStockPurchases`
- `getPurchaseItems`
- `completeStockEntry`

O fluxo permite:

- selecionar o insumo interno correspondente à descrição da NF;
- informar fator de conversão;
- aprender o de-para por fornecedor + descrição;
- finalizar a entrada por RPC.

### 2.3 RPC de finalização

RPC viva verificada:

`public.finalizar_entrada_compra(p_compra_id uuid)`

Comportamento confirmado:

- trava a compra com `FOR UPDATE`;
- retorna sucesso idempotente se a compra já estiver `CONCLUIDO`;
- impede finalização com item sem `insumo_id`;
- grava `ENTRADA_COMPRA` em `movimentacoes_estoque`;
- usa `referencia_id = compra_id`;
- marca `legado = false`;
- atualiza a compra para `CONCLUIDO`.

O conflito histórico `ENTRADA` × `ENTRADA_COMPRA` está encerrado: a implementação atual usa `ENTRADA_COMPRA`.

---

## 3. Teste ponta a ponta realizado

Foi executado um teste real com uma compra contendo `ALFACE CRESPA`.

O fluxo validou:

- compra pendente aparecendo na conciliação;
- criação de insumo de entrada separado do item produzido;
- mapeamento descrição NF → insumo;
- fator de conversão;
- criação do de-para;
- finalização da compra;
- geração de `ENTRADA_COMPRA`;
- atualização de `vw_estoque_master`;
- idempotência da RPC ao tentar finalizar novamente.

Após o teste, os dados de teste foram removidos, incluindo compra, itens, movimentação e de-para criado especificamente para o ensaio.

---

## 4. Descoberta crítica — reimportação da mesma NF

Foi reenviada uma nota já existente para o pipeline n8n.

Resultado:

- `compras`: não duplicou por causa do `ON CONFLICT (chave_acesso)`;
- `compra_itens`: duplicou;
- compra concluída permaneceu concluída;
- estoque não duplicou porque a RPC de finalização é idempotente.

Exemplo verificado:

- item original conciliado possuía `insumo_id` e `fator_conversao` definidos;
- a reimportação criou nova linha em `compra_itens` com `insumo_id = NULL` e fator padrão.

### Regra obrigatória

A ingestão precisa ser idempotente, não apenas a finalização do estoque.

Reenviar a mesma NF não pode:

- criar uma segunda compra;
- duplicar `compra_itens`;
- alterar uma compra já concluída;
- apagar mapeamentos já conciliados;
- gerar nova movimentação de estoque.

### Estado alvo

Se `chave_acesso` já existe e `status_estoque = 'CONCLUIDO'`:

`→ NÃO reimportar itens`  
`→ retornar resultado equivalente a NOTA_JA_PROCESSADA`

Se a compra existe e ainda está `PENDENTE`, o reprocessamento deve ser definido de forma segura e não pode apagar conciliações manuais silenciosamente.

---

## 5. Preços e fator de conversão

Semântica definida para a ingestão:

- `preco_total` = valor líquido efetivo da linha do item após descontos específicos daquele item;
- `preco_unitario` = custo líquido unitário da unidade informada na NF;
- quando o total líquido da linha for confiável: `preco_unitario = preco_total / quantidade_comprada`;
- descontos globais da NF não devem ser rateados automaticamente entre itens.

O Code node do n8n foi ajustado para priorizar o total líquido da linha e recalcular o preço unitário quando necessário.

### Gap de custo no ledger

A RPC atual grava:

`custo_unitario = compra_itens.preco_unitario`

Quando existe `fator_conversao != 1`, o custo unitário da unidade interna deveria considerar a conversão:

`custo_unitario_interno = preco_unitario / fator_conversao`

ou, de forma equivalente:

`preco_total / (quantidade_comprada * fator_conversao)`

Essa correção ainda está pendente.

---

## 6. Gaps ainda abertos

### P0 — idempotência da ingestão n8n

Corrigir a gravação de `compra_itens` para que reenvio da mesma NF seja seguro.

### P0 — local físico da entrada

A RPC atual grava toda compra em:

`local = 'CD'`

Isso está incorreto para fornecedores que entregam diretamente na Loja.

Estado alvo:

- fornecedor → CD: `ENTRADA_COMPRA / CD`;
- fornecedor → Loja: `ENTRADA_COMPRA / LOJA`.

A regra definitiva de resolução do local deve ser implementada antes de considerar o fluxo estabilizado.

### P0 — múltiplas linhas da NF para o mesmo insumo

Se duas linhas de `compra_itens` forem conciliadas para o mesmo `insumo_id` e mesmo local, a inserção no ledger não pode perder quantidade silenciosamente.

A RPC deve agregar ou tratar explicitamente por:

`compra + insumo + local`

antes da inserção.

### P0 — custo após conversão

Aplicar fator de conversão ao custo unitário lançado no ledger.

### P1 — catálogo de insumos da conciliação

Itens com `produzido_internamente = true` não devem aparecer como opção normal de entrada de fornecedor quando representam produto acabado/transformado internamente.

O catálogo de conciliação precisa respeitar essa regra sem misturar matéria-prima comprada com saída de produção.

---

## 7. Segurança operacional

Até a correção da idempotência da ingestão:

- não reenviar intencionalmente uma NF já importada;
- antes de reprocessar uma nota, verificar `chave_acesso` e estado da compra;
- nunca corrigir saldo manualmente;
- qualquer correção de estoque deve ocorrer pelo ledger.

---

## 8. Critérios de aceite

- [x] Compra pendente aparece na tela de conciliação.
- [x] Itens da NF são carregados corretamente.
- [x] Mapeamento para insumo funciona.
- [x] Fator de conversão é persistido.
- [x] De-para é aprendido.
- [x] RPC gera `ENTRADA_COMPRA`.
- [x] `vw_estoque_master` reflete a movimentação.
- [x] RPC é idempotente ao finalizar compra já concluída.
- [x] Normalização do preço líquido da linha foi testada no n8n.
- [ ] Reimportação da mesma NF não duplica `compra_itens`.
- [ ] Compra concluída é protegida contra nova ingestão.
- [ ] Local CD/LOJA é resolvido corretamente.
- [ ] Múltiplas linhas para o mesmo insumo não perdem quantidade.
- [ ] Custo unitário do ledger considera fator de conversão.
- [ ] Produto produzido internamente deixa de aparecer indevidamente na conciliação de fornecedor.

---

## 9. Próxima ação

Corrigir primeiro a idempotência do SQL do node PostgreSQL do n8n.

Depois:

1. repetir teste com NF nova;
2. reenviar a mesma NF;
3. confirmar zero duplicidade em `compras` e `compra_itens`;
4. corrigir local físico, agregação por insumo e custo convertido na RPC;
5. validar novo teste ponta a ponta;
6. somente então concluir `CHANGE-001B`.
