# CHANGE-002A — Fase B2

Esta fase popula `insumo_contexto_estoque` sem ativar consumidores.

Regras:
- CD = `produzido_internamente OR recebido_no_cd`
- LOJA = `enviado_loja`
- `0/0` em gatilho/ideal é aceito
- metas ainda não são migradas
- `modo_reposicao_loja` fica NULL
- todos os contextos ficam `ativo=false`

Os valores globais de gatilho/ideal são apenas copiados como fotografia temporária.
Depois desta validação, a próxima etapa será classificar a Loja em `VOLUME` ou `META_DIA`.
