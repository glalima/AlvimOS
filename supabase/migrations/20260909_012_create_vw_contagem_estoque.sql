-- AlvimOS
-- CHANGE-002B — Fase B
-- Criação da fonte SQL única de contagem Loja/CD
-- Data: 2026-09-09
--
-- Pré-condições:
-- - CHANGE-002A B5 concluída: vw_contexto_estoque_efetivo disponível
-- - CHANGE-002A B6 concluída: meta_estoque_contexto com 145 contextos META_DIA
-- - 327 contextos LOJA + 137 contextos CD
--
-- IMPORTANTE:
-- - a view NÃO filtra contexto_ativo, pois os contextos ainda estão em coexistência
-- - saldo é sempre específico do local
-- - dia da semana é calculado no PostgreSQL em America/Sao_Paulo
-- - nenhuma tela do Retool é alterada nesta migration

BEGIN;

CREATE OR REPLACE VIEW public.vw_contagem_estoque AS
WITH relogio AS (
    SELECT
        timezone('America/Sao_Paulo', now()) AS agora_sao_paulo,
        EXTRACT(
            ISODOW FROM timezone('America/Sao_Paulo', now())
        )::smallint AS dia_semana_atual
)
SELECT
    -- Identidade do contexto
    v.contexto_id,
    v.insumo_id,
    v.insumo_nome,
    v.local,

    -- Classificação efetiva do local
    v.categoria_id,
    v.categoria_nome,
    v.categoria_setor AS setor,

    -- Política herdada / efetiva
    v.modo_reposicao_efetivo,
    v.dias_contagem_efetivos,
    v.ativo_contagem_efetivo,

    -- Relógio operacional
    r.agora_sao_paulo,
    r.dia_semana_atual,

    -- Deve aparecer na contagem hoje?
    (
        v.ativo_contagem_efetivo = true
        AND r.dia_semana_atual = ANY(v.dias_contagem_efetivos)
    ) AS deve_contar_hoje,

    -- Saldos brutos para auditoria
    em.saldo_loja,
    em.saldo_cd,

    -- Saldo que realmente importa para este contexto
    CASE
        WHEN v.local = 'LOJA' THEN COALESCE(em.saldo_loja, 0)
        WHEN v.local = 'CD'   THEN COALESCE(em.saldo_cd, 0)
        ELSE 0
    END::numeric AS saldo_atual,

    -- Indica se o insumo foi encontrado na view mestre de saldo
    (em.insumo_id IS NOT NULL) AS saldo_encontrado,

    -- Meta física do dia:
    -- só possui significado para LOJA + META_DIA
    CASE
        WHEN v.local = 'LOJA'
         AND v.modo_reposicao_efetivo = 'META_DIA'
            THEN mec.quantidade
        ELSE NULL
    END::numeric AS meta_dia,

    -- Parâmetros de volume:
    -- úteis para auditoria e futura reposição, não são "meta do dia"
    v.estoque_gatilho,
    v.estoque_ideal,

    -- Referência de migração; não usada para filtrar nesta fase
    v.contexto_ativo

FROM public.vw_contexto_estoque_efetivo v
CROSS JOIN relogio r
LEFT JOIN public.vw_estoque_master em
    ON em.insumo_id = v.insumo_id
LEFT JOIN public.meta_estoque_contexto mec
    ON mec.contexto_id = v.contexto_id
   AND mec.dia_semana = r.dia_semana_atual;

COMMENT ON VIEW public.vw_contagem_estoque IS
'Fonte SQL única das contagens do ALVIM OS. Resolve local, categoria, setor, saldo específico do local, política efetiva, dias de contagem, deve_contar_hoje e meta do dia para LOJA/META_DIA. Não filtra contexto_ativo durante a coexistência.';

COMMIT;

-- =========================================================
-- VALIDAÇÕES — SOMENTE LEITURA
-- =========================================================

-- A. Cobertura total da view
-- Esperado: 464 linhas = 327 LOJA + 137 CD
SELECT
    COUNT(*) AS total_linhas,
    COUNT(*) FILTER (WHERE local = 'LOJA') AS loja,
    COUNT(*) FILTER (WHERE local = 'CD') AS cd
FROM public.vw_contagem_estoque;

-- B. Contextos sem saldo encontrado
-- Esperado: idealmente 0.
SELECT
    local,
    COUNT(*) AS sem_saldo_encontrado
FROM public.vw_contagem_estoque
WHERE saldo_encontrado = false
GROUP BY local
ORDER BY local;

-- C. Quantos itens devem ser contados hoje por local
SELECT
    dia_semana_atual,
    local,
    COUNT(*) FILTER (WHERE deve_contar_hoje) AS deve_contar_hoje,
    COUNT(*) AS total_contextos
FROM public.vw_contagem_estoque
GROUP BY dia_semana_atual, local
ORDER BY local;

-- D. Itens que devem ser contados hoje agrupados por categoria
SELECT
    local,
    categoria_nome,
    setor,
    COUNT(*) AS total_itens
FROM public.vw_contagem_estoque
WHERE deve_contar_hoje = true
GROUP BY local, categoria_nome, setor
ORDER BY local, categoria_nome;

-- E. META_DIA que deveria ter meta hoje, mas está sem meta
-- Esperado: zero linhas.
SELECT
    contexto_id,
    insumo_nome,
    categoria_nome,
    dia_semana_atual,
    meta_dia
FROM public.vw_contagem_estoque
WHERE local = 'LOJA'
  AND modo_reposicao_efetivo = 'META_DIA'
  AND deve_contar_hoje = true
  AND meta_dia IS NULL
ORDER BY categoria_nome, insumo_nome;

-- F. Contextos VOLUME não devem receber meta_dia
-- Esperado: zero linhas.
SELECT
    contexto_id,
    insumo_nome,
    local,
    categoria_nome,
    modo_reposicao_efetivo,
    meta_dia
FROM public.vw_contagem_estoque
WHERE modo_reposicao_efetivo = 'VOLUME'
  AND meta_dia IS NOT NULL
ORDER BY local, categoria_nome, insumo_nome;

-- G. Amostra operacional Loja de hoje
SELECT
    contexto_id,
    insumo_id,
    insumo_nome,
    categoria_nome,
    setor,
    saldo_atual,
    modo_reposicao_efetivo,
    meta_dia,
    estoque_gatilho,
    estoque_ideal,
    dias_contagem_efetivos,
    deve_contar_hoje
FROM public.vw_contagem_estoque
WHERE local = 'LOJA'
  AND deve_contar_hoje = true
ORDER BY setor, categoria_nome, insumo_nome
LIMIT 100;

-- H. Amostra operacional CD de hoje
SELECT
    contexto_id,
    insumo_id,
    insumo_nome,
    categoria_nome,
    setor,
    saldo_atual,
    estoque_gatilho,
    estoque_ideal,
    dias_contagem_efetivos,
    deve_contar_hoje
FROM public.vw_contagem_estoque
WHERE local = 'CD'
  AND deve_contar_hoje = true
ORDER BY categoria_nome, insumo_nome
LIMIT 100;
