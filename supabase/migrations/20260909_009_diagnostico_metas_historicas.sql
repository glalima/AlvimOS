-- AlvimOS
-- CHANGE-002A — Fase B6
-- Diagnóstico de metas históricas antes da migração
-- SOMENTE LEITURA
-- Data: 2026-09-09
--
-- Objetivo:
-- cruzar meta_estoque legado com vw_contexto_estoque_efetivo
-- e separar:
-- 1) META_DIA + possui meta histórica       -> candidata à migração
-- 2) META_DIA + sem meta histórica          -> precisa parametrização
-- 3) VOLUME + possui meta histórica         -> legado obsoleto / não migrar
-- 4) VOLUME + sem meta histórica            -> coerente

-- =========================================================
-- 1. RESUMO GERAL POR SITUAÇÃO
-- =========================================================
WITH base AS (
    SELECT
        v.contexto_id,
        v.insumo_id,
        v.insumo_nome,
        v.local,
        v.categoria_nome,
        v.modo_reposicao_efetivo,
        CASE WHEN m.id_insumo IS NOT NULL THEN true ELSE false END AS tem_meta_historica,
        m.segunda,
        m.terca,
        m.quarta,
        m.quinta,
        m.sexta,
        m.sabado,
        m.domingo
    FROM public.vw_contexto_estoque_efetivo v
    LEFT JOIN public.meta_estoque m
      ON m.id_insumo = v.insumo_id
    WHERE v.local = 'LOJA'
),
classificado AS (
    SELECT
        *,
        CASE
            WHEN modo_reposicao_efetivo = 'META_DIA'
             AND tem_meta_historica = true
                THEN 'META_DIA_COM_META_HISTORICA'

            WHEN modo_reposicao_efetivo = 'META_DIA'
             AND tem_meta_historica = false
                THEN 'META_DIA_SEM_META_HISTORICA'

            WHEN modo_reposicao_efetivo = 'VOLUME'
             AND tem_meta_historica = true
                THEN 'VOLUME_COM_META_HISTORICA'

            WHEN modo_reposicao_efetivo = 'VOLUME'
             AND tem_meta_historica = false
                THEN 'VOLUME_SEM_META_HISTORICA'

            ELSE 'REVISAR'
        END AS situacao
    FROM base
)
SELECT
    situacao,
    COUNT(*) AS total
FROM classificado
GROUP BY situacao
ORDER BY situacao;

-- =========================================================
-- 2. RESUMO POR CATEGORIA
-- =========================================================
WITH base AS (
    SELECT
        v.insumo_id,
        v.insumo_nome,
        v.categoria_nome,
        v.modo_reposicao_efetivo,
        CASE WHEN m.id_insumo IS NOT NULL THEN true ELSE false END AS tem_meta_historica
    FROM public.vw_contexto_estoque_efetivo v
    LEFT JOIN public.meta_estoque m
      ON m.id_insumo = v.insumo_id
    WHERE v.local = 'LOJA'
)
SELECT
    categoria_nome,
    modo_reposicao_efetivo,
    COUNT(*) AS total_itens,
    COUNT(*) FILTER (WHERE tem_meta_historica = true) AS com_meta_historica,
    COUNT(*) FILTER (WHERE tem_meta_historica = false) AS sem_meta_historica
FROM base
GROUP BY categoria_nome, modo_reposicao_efetivo
ORDER BY categoria_nome;

-- =========================================================
-- 3. META_DIA + COM META HISTÓRICA
-- Candidatos à migração
-- =========================================================
SELECT
    v.contexto_id,
    v.insumo_id,
    v.insumo_nome,
    v.categoria_nome,
    v.modo_reposicao_efetivo,
    m.segunda,
    m.terca,
    m.quarta,
    m.quinta,
    m.sexta,
    m.sabado,
    m.domingo
FROM public.vw_contexto_estoque_efetivo v
JOIN public.meta_estoque m
  ON m.id_insumo = v.insumo_id
WHERE v.local = 'LOJA'
  AND v.modo_reposicao_efetivo = 'META_DIA'
ORDER BY v.categoria_nome, v.insumo_nome;

-- =========================================================
-- 4. META_DIA + SEM META HISTÓRICA
-- Precisam parametrização antes de entrar no motor META_DIA
-- =========================================================
SELECT
    v.contexto_id,
    v.insumo_id,
    v.insumo_nome,
    v.categoria_nome,
    v.modo_reposicao_efetivo
FROM public.vw_contexto_estoque_efetivo v
LEFT JOIN public.meta_estoque m
  ON m.id_insumo = v.insumo_id
WHERE v.local = 'LOJA'
  AND v.modo_reposicao_efetivo = 'META_DIA'
  AND m.id_insumo IS NULL
ORDER BY v.categoria_nome, v.insumo_nome;

-- =========================================================
-- 5. VOLUME + COM META HISTÓRICA
-- Legado obsoleto: NÃO migrar automaticamente
-- =========================================================
SELECT
    v.contexto_id,
    v.insumo_id,
    v.insumo_nome,
    v.categoria_nome,
    v.modo_reposicao_efetivo,
    m.segunda,
    m.terca,
    m.quarta,
    m.quinta,
    m.sexta,
    m.sabado,
    m.domingo
FROM public.vw_contexto_estoque_efetivo v
JOIN public.meta_estoque m
  ON m.id_insumo = v.insumo_id
WHERE v.local = 'LOJA'
  AND v.modo_reposicao_efetivo = 'VOLUME'
ORDER BY v.categoria_nome, v.insumo_nome;

-- =========================================================
-- 6. CONTAGEM DE METAS HISTÓRICAS FORA DE META_DIA
-- Deve ser tratada como legado, não como política ativa
-- =========================================================
SELECT
    COUNT(*) AS metas_historicas_em_itens_volume
FROM public.vw_contexto_estoque_efetivo v
JOIN public.meta_estoque m
  ON m.id_insumo = v.insumo_id
WHERE v.local = 'LOJA'
  AND v.modo_reposicao_efetivo = 'VOLUME';
