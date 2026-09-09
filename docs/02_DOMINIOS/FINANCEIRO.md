# DOMÍNIO — FINANCEIRO

## Objetivo
Separar evento físico de estoque e liquidação financeira.

## Princípio
Uma compra pode:
- ter entrada física concluída;
- continuar pendente financeiramente.

Ou o inverso, conforme fluxo operacional.

## Estado atual
Existem funções/backend para:
- entrada de compra;
- conciliação financeira;
- pendências de estoque;
- pendências financeiras.

## Integração futura
O financeiro deve receber eventos de compras, fornecedores e pagamentos sem controlar saldo físico diretamente.
