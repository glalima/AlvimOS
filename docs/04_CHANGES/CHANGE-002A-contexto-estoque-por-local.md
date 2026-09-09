# CHANGE-002A — Contexto de estoque por local e migração

**Status:** ESPECIFICAÇÃO / NÃO EXECUTAR AINDA  
**Data:** 09/09/2026  
**Domínios:** Insumos, Estoque, Contagem, Reposição, Compras  
**Dependência:** CHANGE-001A estável + ADR-006 aceito

## Objetivo
Separar características globais do insumo das configurações de estoque específicas de LOJA e CD.

## Regra alvo
### Insumo global
- `produzido_internamente`
- `recebido_no_cd`
- `enviado_loja`

`compra_diaria` será descontinuada, mas não removida nesta mudança.

### CD
CD opera por volume:
- categoria/setor do CD;
- política de contagem;
- estoque gatilho;
- estoque ideal.

### Loja
Loja pode operar por:
- `VOLUME`: estoque gatilho + estoque ideal; ou
- `META_DIA`: metas físicas por dia da semana.

Política de contagem é independente da forma de reposição.

## Schema alvo proposto

### `insumo_contexto_estoque`
- `id`
- `insumo_id`
- `local` (`LOJA` | `CD`)
- `categoria_id`
- `setor`
- `dias_contagem_override`
- `modo_reposicao_loja` (`VOLUME` | `META_DIA`, somente LOJA)
- `estoque_gatilho`
- `estoque_ideal`
- `ativo`
- timestamps

Garantir unicidade adequada de contexto por `insumo_id` + `local`.

### `meta_estoque_contexto`
- `contexto_id`
- `dia_semana`
- `quantidade`

Garantir unicidade `(contexto_id, dia_semana)`.

## Estratégia de migration
### Fase A — adicionar
Criar novas tabelas/constraints sem remover ou alterar comportamento legado.

### Fase B — popular
- `recebido_no_cd=true` → contexto CD quando aplicável;
- `enviado_loja=true` → contexto LOJA;
- `categoria_cd` → categoria do contexto CD;
- `categoria_loja` → categoria do contexto LOJA;
- migrar parâmetros de volume somente após definir corretamente a qual local pertencem;
- migrar metas atuais para o contexto LOJA correspondente;
- migrar/herdar política de contagem por categoria/local.

### Fase C — validar
Comparar schema antigo × novo sem trocar consumidores.

Casos obrigatórios:
1. Coca-Cola 2L — Loja por volume, sem meta diária.
2. Tampa 550 ml — CD por volume + Loja por META_DIA.
3. Tomate inteiro — CD sem necessidade de contexto Loja.
4. Entrega direta — Loja com `recebido_no_cd=false`.
5. Produzido internamente — existência no CD mesmo sem recebimento externo.

### Fase D — trocar consumidores
Somente após validação:
- cadastro;
- contagem;
- reposição;
- compras.

## Coexistência obrigatória
Nesta CHANGE não remover:
- `compra_diaria`;
- `categoria_loja`;
- `categoria_cd`;
- `setores`;
- `gatilho_pedido`;
- `estoque_ideal`;
- `meta_estoque`.

A remoção ocorrerá em CHANGE posterior após ausência comprovada de consumidores.

## Banco afetado
- `insumos` (origem para migração; sem remoção);
- `categorias`;
- `meta_estoque`;
- novas tabelas de contexto;
- posteriormente views/RPCs consumidoras.

## Riscos
- atribuir gatilho/ideal global ao local errado;
- criar contexto CD para item que apenas existe na Loja;
- perder metas existentes;
- duplicar regras entre SQL e Retool;
- trocar consumidores antes de validar a migração.

## Critério de aceite
Todos os insumos relevantes possuem contexto(s) coerentes e os cinco casos reais passam na comparação antigo × novo antes de qualquer desativação do modelo legado.
