-- AlvimOS
-- CHANGE-002A — Fase A
-- Cria o novo modelo de contexto de estoque por local.
-- MIGRATION ADITIVA: não remove nem altera colunas legadas.
-- Data: 2026-09-09

BEGIN;

CREATE TABLE IF NOT EXISTS public.insumo_contexto_estoque (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    insumo_id uuid NOT NULL
        REFERENCES public.insumos(id)
        ON DELETE CASCADE,

    local text NOT NULL
        CHECK (local IN ('LOJA', 'CD')),

    categoria_id uuid
        REFERENCES public.categorias(id)
        ON DELETE SET NULL,

    -- NULL = herda a política de contagem da categoria/local.
    -- Quando preenchido: 1=segunda ... 7=domingo.
    dias_contagem_override smallint[],

    -- Somente relevante para LOJA.
    -- No CD a recomposição é sempre por volume.
    modo_reposicao_loja text
        CHECK (
            modo_reposicao_loja IS NULL
            OR modo_reposicao_loja IN ('VOLUME', 'META_DIA')
        ),

    -- Parâmetros de recomposição por volume do contexto.
    estoque_gatilho numeric(10,2),
    estoque_ideal numeric(10,2),

    -- Durante a migração os contextos poderão existir antes
    -- de serem habilitados como fonte oficial das telas.
    ativo boolean NOT NULL DEFAULT false,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_insumo_contexto_local UNIQUE (insumo_id, local),

    CONSTRAINT ck_contexto_valores_nao_negativos CHECK (
        (estoque_gatilho IS NULL OR estoque_gatilho >= 0)
        AND
        (estoque_ideal IS NULL OR estoque_ideal >= 0)
    ),

    CONSTRAINT ck_contexto_ideal_maior_igual_gatilho CHECK (
        estoque_gatilho IS NULL
        OR estoque_ideal IS NULL
        OR estoque_ideal >= estoque_gatilho
    ),

    CONSTRAINT ck_contexto_modo_apenas_loja CHECK (
        local = 'LOJA'
        OR modo_reposicao_loja IS NULL
    ),

    CONSTRAINT ck_dias_contagem_override CHECK (
        dias_contagem_override IS NULL
        OR dias_contagem_override <@ ARRAY[1,2,3,4,5,6,7]::smallint[]
    )
);

CREATE INDEX IF NOT EXISTS idx_insumo_contexto_local
    ON public.insumo_contexto_estoque(local);

CREATE INDEX IF NOT EXISTS idx_insumo_contexto_categoria
    ON public.insumo_contexto_estoque(categoria_id);

CREATE INDEX IF NOT EXISTS idx_insumo_contexto_ativo
    ON public.insumo_contexto_estoque(local, ativo);


CREATE TABLE IF NOT EXISTS public.meta_estoque_contexto (
    contexto_id uuid NOT NULL
        REFERENCES public.insumo_contexto_estoque(id)
        ON DELETE CASCADE,

    -- ISO-like: 1=segunda ... 7=domingo.
    dia_semana smallint NOT NULL
        CHECK (dia_semana BETWEEN 1 AND 7),

    quantidade numeric(10,2) NOT NULL
        CHECK (quantidade >= 0),

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    PRIMARY KEY (contexto_id, dia_semana)
);

CREATE INDEX IF NOT EXISTS idx_meta_estoque_contexto_contexto
    ON public.meta_estoque_contexto(contexto_id);


COMMENT ON TABLE public.insumo_contexto_estoque IS
'Configuração operacional do estoque de um insumo em um local físico (LOJA ou CD).';

COMMENT ON COLUMN public.insumo_contexto_estoque.local IS
'Local físico do estoque. LOJA ou CD.';

COMMENT ON COLUMN public.insumo_contexto_estoque.categoria_id IS
'Categoria válida para este insumo neste local. O setor é derivado da categoria.';

COMMENT ON COLUMN public.insumo_contexto_estoque.dias_contagem_override IS
'Override opcional da frequência de contagem. NULL herda da categoria. 1=segunda ... 7=domingo.';

COMMENT ON COLUMN public.insumo_contexto_estoque.modo_reposicao_loja IS
'Somente LOJA: VOLUME ou META_DIA. No CD a política é sempre volume.';

COMMENT ON COLUMN public.insumo_contexto_estoque.estoque_gatilho IS
'Em política por volume, nível a partir do qual o contexto deve ser recomposto.';

COMMENT ON COLUMN public.insumo_contexto_estoque.estoque_ideal IS
'Em política por volume, alvo de estoque após recomposição.';

COMMENT ON TABLE public.meta_estoque_contexto IS
'Metas físicas por dia da semana para contextos de LOJA que operam em META_DIA.';

COMMIT;
