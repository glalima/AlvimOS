# CHANGE-002A — Fase A: primeira migration

Esta é a primeira implementação estrutural do novo modelo.

## O que ela faz

Cria somente:

- `insumo_contexto_estoque`
- `meta_estoque_contexto`

Não altera o comportamento do app e não remove nada do modelo antigo.

## Refinamento importante

O contexto **não armazena `setor` diretamente**.

Hoje `categorias` já possui `setor`, portanto guardar `categoria_id` + `setor` duplicaria a mesma informação e permitiria inconsistências.

A regra passa a ser:

`contexto.categoria_id → categorias.setor`

## Por que `ativo` começa como false

Vamos primeiro migrar e comparar os dados.

Somente depois de validar Coca 2L, Tampa 550, Tomate, entrega direta e produzidos internos é que o novo contexto passa a ser usado pelas telas.

## O que NÃO fazer depois desta migration

Não remover:
- `compra_diaria`
- `categoria_loja`
- `categoria_cd`
- `setores`
- `gatilho_pedido`
- `estoque_ideal`
- `meta_estoque`

Não alterar ainda:
- telas de contagem
- cadastro
- painel de compras

## Próxima Fase B

Depois de confirmar que a migration foi criada corretamente, vamos gerar os contextos a partir do modelo atual, mas sem ativá-los.

A migração dos dados terá regras diferentes para:
- contexto CD;
- contexto Loja;
- parâmetros de volume;
- metas históricas, que NÃO serão copiadas cegamente.
