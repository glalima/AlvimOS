-- AlvimOS
-- CHANGE-002A — Fase B5
-- Herança efetiva de políticas: override do contexto ?? padrão da categoria
-- Data: 2026-09-09
--
-- Pré-condições:
-- - B3 concluída: categorias possuem modo_reposicao_padrao,
--   dias_contagem_padrao e ativo_contagem.
-- - B4 concluída: contexto CD referencia categoria tipo='CD'
--   e contexto LOJA referencia categoria tipo='LOJA'.
--
-- Esta migration:
-- 1) renomeia o campo legado de contexto para semântica de override;
-- 2) mantém dias_contagem_override como override já existente;
-- 3) cria uma view SQL única com as políticas efetivas;
-- 4) não ativa consumidores nem altera telas nesta fase.

BEGIN;

-- =========================================================
-- 1. RENOMEAR CAMPO DO CONTEXTO PARA OVERRIDE
-- =========================================================
-- A coluna foi criada na Fase A como modo_reposicao_loja.
-- Como agora a categoria é a fonte do default, o campo do contexto
-- passa a representar SOMENTE exceção.

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'insumo_contexto_estoque'
          AND column_name = 'modo_reposicao_loja'
    )
    AND NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'insumo_contexto_estoque'
          AND column_name = 'modo_reposicao_override'
    ) THEN
        ALTER TABLE public.insumo_contexto_estoque
            RENAME COLUMN modo_reposicao_loja TO modo_reposicao_override;
    END IF;
END $$;

COMMENT ON COLUMN public.insumo_contexto_estoque.modo_reposicao_override IS
'Override opcional da política de reposição do contexto. NULL = herda modo_reposicao_padrao da categoria. No CD deve permanecer NULL, pois CD é sempre VOLUME.';

COMMENT ON COLUMN public.insumo_contexto_estoque.dias_contagem_override IS
'Override opcional dos dias de contagem do contexto. NULL = herda dias_contagem_padrao da categoria. 1=segunda ... 7=domingo.';

-- =========================================================
-- 2. VIEW DE POLÍTICA EFETIVA POR CONTEXTO
-- =========================================================

CREATE OR REPLACE VIEW public.vw_contexto_estoque_efetivo AS
SELECT
    ic.id AS contexto_id,
    ic.insumo_id,
    i.nome AS insumo_nome,

    ic.local,

    ic.categoria_id,
    c.nome AS categoria_nome,
    c.tipo AS categoria_tipo,
    c.setor AS categoria_setor,

    -- Configuração padrão da categoria
    c.modo_reposicao_padrao,
    c.dias_contagem_padrao,
    c.ativo_contagem AS categoria_ativo_contagem,

    -- Overrides do contexto
    ic.modo_reposicao_override,
    ic.dias_contagem_override,

    -- Política efetiva
    CASE
        WHEN ic.local = 'CD' THEN 'VOLUME'
        ELSE COALESCE(
            ic.modo_reposicao_override,
            c.modo_reposicao_padrao
        )
    END AS modo_reposicao_efetivo,

    COALESCE(
        ic.dias_contagem_override,
        c.dias_contagem_padrao
    ) AS dias_contagem_efetivos,

    COALESCE(c.ativo_contagem, false) AS ativo_contagem_efetivo,

    -- Parâmetros específicos do contexto
    ic.estoque_gatilho,
    ic.estoque_ideal,

    -- Estado de migração do contexto
    ic.ativo AS contexto_ativo,

    -- Dados logísticos globais ainda com nomes físicos legados
    i.produzido_internamente,
    i.recebido_no_cd,
    i.enviado_loja,

    ic.created_at,
    ic.updated_at

FROM public.insumo_contexto_estoque ic
JOIN public.insumos i
    ON i.id = ic.insumo_id
JOIN public.categorias c
    ON c.id = ic.categoria_id;

COMMENT ON VIEW public.vw_contexto_estoque_efetivo IS
'Fonte SQL da configuração efetiva de estoque por contexto. Resolve política por herança: override do contexto ?? padrão da categoria. CD é sempre VOLUME.';

COMMIT;

-- =========================================================
-- 3. VALIDAÇÃO
-- =========================================================

-- A. Totais e políticas efetivas por local
SELECT
    local,
    modo_reposicao_efetivo,
    COUNT(*) AS total
FROM public.vw_contexto_estoque_efetivo
GROUP BY local, modo_reposicao_efetivo
ORDER BY local, modo_reposicao_efetivo;

-- B. Não pode haver contexto sem política efetiva
SELECT
    contexto_id,
    insumo_nome,
    local,
    categoria_nome,
    modo_reposicao_padrao,
    modo_reposicao_override,
    modo_reposicao_efetivo
FROM public.vw_contexto_estoque_efetivo
WHERE modo_reposicao_efetivo IS NULL
ORDER BY local, categoria_nome, insumo_nome;

-- C. Não pode haver contexto ativo para contagem sem dias efetivos
SELECT
    contexto_id,
    insumo_nome,
    local,
    categoria_nome,
    dias_contagem_padrao,
    dias_contagem_override,
    dias_contagem_efetivos
FROM public.vw_contexto_estoque_efetivo
WHERE ativo_contagem_efetivo = true
  AND dias_contagem_efetivos IS NULL
ORDER BY local, categoria_nome, insumo_nome;

-- D. CD deve ser exclusivamente VOLUME
SELECT
    contexto_id,
    insumo_nome,
    categoria_nome,
    modo_reposicao_override,
    modo_reposicao_efetivo
FROM public.vw_contexto_estoque_efetivo
WHERE local = 'CD'
  AND modo_reposicao_efetivo IS DISTINCT FROM 'VOLUME'
ORDER BY categoria_nome, insumo_nome;

-- E. Mostrar distribuição por categoria da Loja
SELECT
    categoria_nome,
    modo_reposicao_padrao,
    modo_reposicao_efetivo,
    COUNT(*) AS total_itens
FROM public.vw_contexto_estoque_efetivo
WHERE local = 'LOJA'
GROUP BY categoria_nome, modo_reposicao_padrao, modo_reposicao_efetivo
ORDER BY categoria_nome, modo_reposicao_efetivo;
