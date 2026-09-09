# CHANGE-002A — Fase B

**Status:** PRÓXIMA IMPLEMENTAÇÃO  
**Data:** 09/09/2026

## Objetivo
Popular `insumo_contexto_estoque` sem ativar consumidores e sem apagar o modelo antigo.

## Mapeamento temporário
- `recebido_no_cd` = `recebido_externamente_no_cd`;
- `enviado_loja` = `controlado_na_loja`.

## Criação objetiva de contextos

```text
CD:
produzido_internamente = true
OR recebido_no_cd = true

LOJA:
enviado_loja = true
```

Todos permanecem inicialmente `ativo=false`.

## Categorias
- CD recebe `categoria_cd`;
- LOJA recebe `categoria_loja`;
- setor é derivado de `categorias.setor`.

## Não inferir automaticamente ainda
- VOLUME vs META_DIA da Loja;
- validade de metas históricas;
- destino de gatilho/ideal global em casos ambíguos.

## Sequência
1. preview SQL dos contextos candidatos;
2. conferir totais e casos sem categoria;
3. inserir contextos inativos;
4. gerar diagnóstico Loja para VOLUME/META_DIA;
5. revisar conflitos históricos;
6. migrar metas e parâmetros somente após classificação.
