# DOMÍNIO — PRODUÇÃO

## Situação
O CD do Alvim não é apenas depósito; também transforma matérias-primas.

Exemplos:
- tomate inteiro → rodelas / picado;
- matérias-primas → produtos manipulados.

## Combinação relevante
`produzido_internamente = false`
`recebido_no_cd = true`
`enviado_loja = false`

Representa matéria-prima que chega ao CD e pode ser consumida em produção antes de existir na Loja.

## Produto produzido
Pode ter:
`produzido_internamente = true`
`recebido_no_cd = false`
`enviado_loja = true`

e ainda existir fisicamente no CD antes do envio.

## Futuro
- ordem de produção;
- ficha técnica;
- consumo de matérias-primas;
- entrada de produto;
- rendimento;
- perda;
- lote;
- validade.

## Regra
Não misturar produção com compra ou reposição para simplificar o código.
