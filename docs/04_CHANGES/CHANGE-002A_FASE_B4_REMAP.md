# CHANGE-002A — Fase B4 — Remapeamento de categorias CD

## Decisão

Foi aprovado manualmente um mapa entre categorias legadas usadas no contexto CD e categorias oficiais do CD.

A migration remapeia apenas conversões explícitas, por exemplo:

- `2 - Hortifruti` → `Refrigerados & Laticínios`
- `5 - Embalagens` → `Embalagens Master & Caixas`
- `Cigarros` → `CIGARROS`

## Casos "não tem no CD"

Esses casos NÃO são apagados automaticamente nesta migration.

Motivo: se ainda existe um contexto CD para um item cuja categoria operacional não deveria existir no CD, então o problema provavelmente está na origem do contexto:

- `recebido_no_cd = true` indevido;
- ou regra/legado de `produzido_internamente`.

Excluir o contexto automaticamente esconderia a inconsistência.

Depois do remapeamento, a validação lista apenas esses casos restantes para uma correção estrutural separada.

## Próximo passo esperado

Após executar a migration:

1. confirmar redução das incompatibilidades CD;
2. analisar somente os contextos restantes;
3. corrigir booleanas/contextos indevidos;
4. chegar a zero contextos CD com categoria tipo LOJA;
5. então seguir para herança efetiva `override ?? padrão_da_categoria`.
