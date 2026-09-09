# DOMÍNIO — COMPRAS

## Objetivo
Determinar o que precisa entrar de fora da empresa.

## Princípio
Compra deve ser calculada a partir do local que o fornecedor efetivamente abastece.

## Casos consolidados

### Recebido no CD
Fornecedor abastece CD.

Exemplo Tampas:
- `recebido_no_cd = true`
- compra do fornecedor deve considerar saldo CD, gatilho e ideal;
- meta da Loja continua sendo usada apenas para reposição.

### Entrega direta à Loja
- `recebido_no_cd = false`
- `enviado_loja = true`
- saldo relevante tende a ser Loja.

A política exata de compra direta deve ser formalizada no CHANGE antes da implementação final.

## Estado atual
Backend:
`backend/reposicoes/getPainelCompras.ts`

Executa:
`SELECT * FROM view_painel_compras`

## Gap crítico
`view_painel_compras` não aparece no dump analisado.

## Estado alvo
View SQL como motor.

Entradas esperadas:
- insumo
- contexto abastecido
- saldo relevante
- estoque mínimo
- gatilho
- ideal
- fornecedor
- última compra
- preço
- status
- quantidade sugerida

## Não fazer
- duplicar fórmula no React;
- usar `meta_estoque` do CD;
- assumir que `compra_diaria=true` elimina gatilho/ideal quando o item é recebido no CD.
