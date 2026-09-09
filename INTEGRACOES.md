# DOMÍNIO — INTEGRAÇÕES

## Objetivo
Conectar ALVIM OS a fontes externas sem acoplar o núcleo a formatos de terceiros.

## Primeira integração analisada
Saipos.

## Piloto recomendado
Cigarros ou outra categoria 1:1 entre venda e consumo.

## Arquitetura sugerida
SAIPOS
→ ingestão
→ staging/raw
→ de-para
→ validação
→ eventos de consumo
→ ledger

## Requisitos
- token fora do frontend;
- sincronização incremental;
- idempotência;
- tratamento de cancelamentos;
- observabilidade;
- modo simulação antes de movimentar estoque.

## Observação
A API de movimentação de estoque Saipos foi documentada como "em manutenção"; não torná-la dependência crítica sem validação.
