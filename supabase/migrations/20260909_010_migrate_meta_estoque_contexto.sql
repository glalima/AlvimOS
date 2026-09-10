-- AlvimOS
-- CHANGE-002A — Fase B6
-- Migração das metas válidas para meta_estoque_contexto
-- Data: 2026-09-09
--
-- Regra:
-- somente contextos LOJA cuja política efetiva seja META_DIA
-- recebem metas no novo modelo.
--
-- Esperado no estado validado:
-- 145 contextos META_DIA
-- 7 dias por contexto
-- 1.015 linhas em meta_estoque_contexto
--
-- Metas históricas dos 182 itens VOLUME permanecem intactas em
-- meta_estoque, mas NÃO são migradas.

BEGIN;

-- =========================================================
-- 0. PRECHECKS
-- =========================================================

-- Confirma schema esperado da tabela nova.
DO $$
DECLARE
    faltantes text;
BEGIN
    SELECT string_agg(x.coluna, ', ')
      INTO faltantes
    FROM (
        VALUES
            ('contexto_id'),
            ('dia_semana'),
            ('quantidade')
    ) AS x(coluna)
    WHERE NOT EXISTS (
        SELECT 1
        FROM information_schema.columns c
        WHERE c.table_schema = 'public'
          AND c.table_name = 'meta_estoque_contexto'
          AND c.column_name = x.coluna
    );

    IF faltantes IS NOT NULL THEN
        RAISE EXCEPTION
            'B6 abortada: meta_estoque_contexto não possui as colunas esperadas: %',
            faltantes;
    END IF;
END $$;

-- Não aceitar duplicidade histórica por insumo, pois tornaria
-- a origem da migração ambígua.
DO $$
DECLARE
    duplicados integer;
BEGIN
    SELECT COUNT(*)
      INTO duplicados
    FROM (
        SELECT m.id_insumo
        FROM public.meta_estoque m
        GROUP BY m.id_insumo
        HAVING COUNT(*) > 1
    ) d;

    IF duplicados > 0 THEN
        RAISE EXCEPTION
            'B6 abortada: existem % insumos com mais de uma linha em meta_estoque.',
            duplicados;
    END IF;
END $$;

-- Valida a fotografia aprovada antes de gravar.
DO $$
DECLARE
    qtd_contextos integer;
    qtd_com_meta integer;
BEGIN
    SELECT COUNT(*)
      INTO qtd_contextos
    FROM public.vw_contexto_estoque_efetivo v
    WHERE v.local = 'LOJA'
      AND v.modo_reposicao_efetivo = 'META_DIA';

    SELECT COUNT(*)
      INTO qtd_com_meta
    FROM public.vw_contexto_estoque_efetivo v
    JOIN public.meta_estoque m
      ON m.id_insumo = v.insumo_id
    WHERE v.local = 'LOJA'
      AND v.modo_reposicao_efetivo = 'META_DIA';

    IF qtd_contextos <> 145 THEN
        RAISE EXCEPTION
            'B6 abortada: esperado 145 contextos META_DIA, encontrado %.',
            qtd_contextos;
    END IF;

    IF qtd_com_meta <> qtd_contextos THEN
        RAISE EXCEPTION
            'B6 abortada: existem contextos META_DIA sem meta histórica. Contextos=%, com meta=%',
            qtd_contextos, qtd_com_meta;
    END IF;
END $$;

-- =========================================================
-- 1. LIMPAR SOMENTE O DESTINO DOS CONTEXTOS META_DIA
-- =========================================================
-- Torna a migration repetível sem tocar em qualquer outro contexto.

DELETE FROM public.meta_estoque_contexto mec
USING public.vw_contexto_estoque_efetivo v
WHERE mec.contexto_id = v.contexto_id
  AND v.local = 'LOJA'
  AND v.modo_reposicao_efetivo = 'META_DIA';

-- =========================================================
-- 2. MIGRAR / NORMALIZAR 7 DIAS POR CONTEXTO
-- =========================================================

INSERT INTO public.meta_estoque_contexto (
    contexto_id,
    dia_semana,
    quantidade
)
SELECT
    v.contexto_id,
    d.dia_semana,
    d.quantidade
FROM public.vw_contexto_estoque_efetivo v
JOIN public.meta_estoque m
  ON m.id_insumo = v.insumo_id
CROSS JOIN LATERAL (
    VALUES
        (1::smallint, m.segunda),
        (2::smallint, m.terca),
        (3::smallint, m.quarta),
        (4::smallint, m.quinta),
        (5::smallint, m.sexta),
        (6::smallint, m.sabado),
        (7::smallint, m.domingo)
) AS d(dia_semana, quantidade)
WHERE v.local = 'LOJA'
  AND v.modo_reposicao_efetivo = 'META_DIA';

-- =========================================================
-- 3. GARANTIAS ANTES DO COMMIT
-- =========================================================

DO $$
DECLARE
    total_linhas integer;
    total_contextos integer;
    contextos_incompletos integer;
    volume_migrado integer;
BEGIN
    SELECT COUNT(*)
      INTO total_linhas
    FROM public.meta_estoque_contexto mec
    JOIN public.vw_contexto_estoque_efetivo v
      ON v.contexto_id = mec.contexto_id
    WHERE v.local = 'LOJA'
      AND v.modo_reposicao_efetivo = 'META_DIA';

    SELECT COUNT(DISTINCT mec.contexto_id)
      INTO total_contextos
    FROM public.meta_estoque_contexto mec
    JOIN public.vw_contexto_estoque_efetivo v
      ON v.contexto_id = mec.contexto_id
    WHERE v.local = 'LOJA'
      AND v.modo_reposicao_efetivo = 'META_DIA';

    SELECT COUNT(*)
      INTO contextos_incompletos
    FROM (
        SELECT mec.contexto_id
        FROM public.meta_estoque_contexto mec
        JOIN public.vw_contexto_estoque_efetivo v
          ON v.contexto_id = mec.contexto_id
        WHERE v.local = 'LOJA'
          AND v.modo_reposicao_efetivo = 'META_DIA'
        GROUP BY mec.contexto_id
        HAVING COUNT(*) <> 7
    ) x;

    SELECT COUNT(*)
      INTO volume_migrado
    FROM public.meta_estoque_contexto mec
    JOIN public.vw_contexto_estoque_efetivo v
      ON v.contexto_id = mec.contexto_id
    WHERE v.local = 'LOJA'
      AND v.modo_reposicao_efetivo = 'VOLUME';

    IF total_linhas <> 1015 THEN
        RAISE EXCEPTION
            'B6 abortada: esperado 1015 metas migradas, encontrado %.',
            total_linhas;
    END IF;

    IF total_contextos <> 145 THEN
        RAISE EXCEPTION
            'B6 abortada: esperado 145 contextos com metas, encontrado %.',
            total_contextos;
    END IF;

    IF contextos_incompletos <> 0 THEN
        RAISE EXCEPTION
            'B6 abortada: % contextos META_DIA não possuem exatamente 7 dias.',
            contextos_incompletos;
    END IF;

    IF volume_migrado <> 0 THEN
        RAISE EXCEPTION
            'B6 abortada: foram encontradas % metas novas ligadas a contextos VOLUME.',
            volume_migrado;
    END IF;
END $$;

COMMIT;

-- =========================================================
-- 4. VALIDAÇÃO PÓS-MIGRAÇÃO — SOMENTE LEITURA
-- =========================================================

-- A. Resumo principal
SELECT
    COUNT(*) AS total_metas_contexto,
    COUNT(DISTINCT contexto_id) AS total_contextos_com_meta
FROM public.meta_estoque_contexto;

-- B. Distribuição por política efetiva
SELECT
    v.local,
    v.modo_reposicao_efetivo,
    COUNT(DISTINCT mec.contexto_id) AS contextos_com_meta,
    COUNT(*) AS linhas_meta
FROM public.meta_estoque_contexto mec
JOIN public.vw_contexto_estoque_efetivo v
  ON v.contexto_id = mec.contexto_id
GROUP BY v.local, v.modo_reposicao_efetivo
ORDER BY v.local, v.modo_reposicao_efetivo;

-- C. Contextos META_DIA que não possuem exatamente 7 dias
-- Esperado: zero linhas.
SELECT
    v.contexto_id,
    v.insumo_nome,
    v.categoria_nome,
    COUNT(mec.dia_semana) AS dias_cadastrados
FROM public.vw_contexto_estoque_efetivo v
LEFT JOIN public.meta_estoque_contexto mec
  ON mec.contexto_id = v.contexto_id
WHERE v.local = 'LOJA'
  AND v.modo_reposicao_efetivo = 'META_DIA'
GROUP BY v.contexto_id, v.insumo_nome, v.categoria_nome
HAVING COUNT(mec.dia_semana) <> 7
ORDER BY v.categoria_nome, v.insumo_nome;

-- D. Metas indevidas em VOLUME
-- Esperado: zero linhas.
SELECT
    v.contexto_id,
    v.insumo_nome,
    v.categoria_nome,
    COUNT(*) AS linhas_meta
FROM public.meta_estoque_contexto mec
JOIN public.vw_contexto_estoque_efetivo v
  ON v.contexto_id = mec.contexto_id
WHERE v.modo_reposicao_efetivo = 'VOLUME'
GROUP BY v.contexto_id, v.insumo_nome, v.categoria_nome
ORDER BY v.categoria_nome, v.insumo_nome;

-- E. Auditoria do caso MORANGO (meta histórica 0 em todos os dias)
SELECT
    v.insumo_nome,
    v.categoria_nome,
    mec.dia_semana,
    mec.quantidade
FROM public.meta_estoque_contexto mec
JOIN public.vw_contexto_estoque_efetivo v
  ON v.contexto_id = mec.contexto_id
WHERE v.insumo_nome = 'MORANGO'
  AND v.categoria_nome = '6 - Frutas'
ORDER BY mec.dia_semana;
