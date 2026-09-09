# DOMÍNIO — INSUMOS

## Objetivo
Cadastrar as propriedades intrínsecas e logísticas dos insumos.

## Estado atual
Tabela `insumos` contém:
- identificação;
- unidade;
- campos de volume;
- 4 chaves;
- classificação Loja/CD ainda embutida;
- campos legados.

Backend:
- `createInsumo.ts`
- `updateInsumo.ts`
- `getInsumosCatalog.ts`

Frontend:
- `InsumosCatalog.tsx`
- `InsumoFormDialog.tsx`

## Problemas verificados

### Catálogo incompleto
`getInsumosCatalog.ts` não retorna:
- `gatilho_pedido`
- `recebido_no_cd`
- `enviado_loja`
- `compra_diaria`

### Defaults perigosos
O formulário pode interpretar `undefined` como default e salvar outra configuração.

### Metas
As metas não são carregadas junto do cadastro.
O formulário inicia metas vazias.

### Regra duplicada
Create e update possuem intertravamentos e cálculos semelhantes.

### Inconsistência de volume
O backend atual define:
`requiresVolume = !compra_diaria && !produzido_internamente`

Isso não atende o caso consolidado de itens recebidos no CD com `compra_diaria=true` que ainda precisam de gatilho/ideal para o CD.

## Estado alvo
- `vw_insumos_cadastro`
- RPC transacional única `salvar_insumo`
- contexto por local separado
- backend fino
- tela apenas edita dados e navega

## Regra de UX
Salvar/Anterior/Próximo é navegação de interface, não regra de banco.
