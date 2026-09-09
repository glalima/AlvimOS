# DATABASE — Taxonomia de movimentações

## Taxonomia operacional atual reconhecida

### Entradas
- `ENTRADA_COMPRA`
- `ENTRADA_TRANSFERENCIA`
- `AJUSTE_ENTRADA`

### Saídas
- `SAIDA_CONSUMO`
- `SAIDA_TRANSFERENCIA`
- `AJUSTE_SAIDA`

## Princípios
- quantidade deve ser positiva;
- direção vem do tipo;
- local obrigatório semanticamente;
- referência deve ligar o evento de origem quando possível.

## Reservado para evolução
- produção;
- perda;
- desperdício;
- devolução.

## Legado
`AJUSTE_CONTAGEM` não deve ser usado em novos fluxos.
