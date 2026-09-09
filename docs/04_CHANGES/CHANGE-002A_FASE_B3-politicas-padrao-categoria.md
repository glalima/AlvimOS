# CHANGE-002A — Fase B3 — Políticas padrão por categoria

**Status:** PRONTA PARA IMPLEMENTAÇÃO  
**Data:** 09/09/2026  
**Dependência:** Fases A, B1 e B2 concluídas e validadas

## Objetivo

Institucionalizar no banco as políticas operacionais padrão por categoria e abandonar a tentativa de inferir a política de cada insumo individualmente a partir do legado.

A nova regra é:

```text
CATEGORIA
→ define o padrão

INSUMO/CONTEXTO
→ define apenas override quando necessário
```

A política efetiva será:

```text
POLÍTICA EFETIVA
=
override do contexto
?? padrão da categoria
```

## Decisão da Fase B3

A Fase B3 anterior, baseada em classificações como:

- `META_DIA_PROVAVEL`;
- `VOLUME_PROVAVEL`;
- `REVISAR_CONFLITO_META_E_VOLUME`;
- `VOLUME_NAO_PARAMETRIZADO`;

foi descartada antes da execução.

Não será feita inferência automática item a item.

A decisão operacional foi definida manualmente por categoria.

## Novos campos em `categorias`

Adicionar:

### `modo_reposicao_padrao`

Valores:
- `VOLUME`
- `META_DIA`

Regra:
- categorias CD usam sempre `VOLUME`;
- categorias LOJA podem usar `VOLUME` ou `META_DIA`.

### `dias_contagem_padrao`

Array de dias:

```text
1 = segunda
2 = terça
3 = quarta
4 = quinta
5 = sexta
6 = sábado
7 = domingo
```

### `ativo_contagem`

Boolean:
- `true` = categoria participa da rotina de contagem;
- `false` = categoria não participa.

## Campos que NÃO pertencem à categoria

Não mover para categoria:

- `estoque_gatilho`
- `estoque_ideal`

Esses valores continuam específicos do insumo/contexto.

## Overrides futuros no contexto

`insumo_contexto_estoque` deverá suportar:

- `modo_reposicao_loja_override`
- `dias_contagem_override`

`NULL` significa herdar da categoria.

## Fonte dos valores

Os valores de `modo_reposicao_padrao`, `dias_contagem_padrao` e `ativo_contagem` foram definidos manualmente por categoria no arquivo de trabalho `categorias_rows (2).csv`.

As demais colunas da tabela `categorias` permanecem inalteradas.

## Escopo da implementação B3

1. adicionar as três novas colunas em `categorias`;
2. preencher as categorias existentes conforme os valores definidos;
3. criar a categoria CD de Cigarros, necessária para separar o contexto CD da categoria Loja;
4. validar a integridade das políticas;
5. não alterar consumidores ainda.

## Fora de escopo

Nesta fase não:

- remover `compra_diaria`;
- migrar `meta_estoque`;
- ativar contextos;
- alterar telas de contagem;
- reconstruir Painel de Compras;
- alterar gatilho/ideal;
- implementar ainda os overrides no frontend.

## Validações obrigatórias

Após a migration:

1. nenhuma categoria utilizada deve ficar sem `modo_reposicao_padrao`;
2. nenhuma categoria ativa para contagem deve ficar sem `dias_contagem_padrao`;
3. toda categoria CD deve ter `modo_reposicao_padrao = VOLUME`;
4. categorias LOJA podem ser `VOLUME` ou `META_DIA`;
5. a nova categoria Cigarros/CD deve existir;
6. nenhuma categoria existente deve perder seus campos anteriores.

## Próximo passo

Após concluir a B3:

1. revisar/remapear `categoria_id` dos contextos para garantir compatibilidade de local;
2. implementar a resolução efetiva:
   `override ?? padrão_da_categoria`;
3. migrar metas somente para contextos LOJA cuja política efetiva seja `META_DIA`;
4. preparar as views de contagem para consumir a política efetiva.

## Critério de aceite

A B3 estará concluída quando as categorias possuírem defaults válidos e o modelo estiver pronto para que os contextos herdem essas políticas sem duplicação.
