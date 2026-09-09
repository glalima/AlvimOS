-- AlvimOS
-- CHANGE-002A — Fase B3
-- Políticas padrão por categoria
-- Fonte: categorias_rows (2).csv
-- Data: 2026-09-09
--
-- IMPORTANTE:
-- Execute este arquivo INTEIRO de uma vez no SQL Editor do Supabase.
--
-- Esta migration:
-- 1) adiciona as 3 colunas novas de política;
-- 2) preenche as decisões aprovadas para as categorias existentes;
-- 3) cria a categoria CIGARROS / CD;
-- 4) mantém todo o restante do modelo atual intacto.
--
-- O local da categoria é representado fisicamente por categorias.tipo
-- ('LOJA' ou 'CD'). Não existe coluna categorias.local.

BEGIN;

-- =========================================================
-- 1. NOVAS COLUNAS
-- =========================================================

ALTER TABLE public.categorias
    ADD COLUMN IF NOT EXISTS modo_reposicao_padrao text,
    ADD COLUMN IF NOT EXISTS dias_contagem_padrao smallint[],
    ADD COLUMN IF NOT EXISTS ativo_contagem boolean NOT NULL DEFAULT true;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'categorias_modo_reposicao_padrao_check'
          AND conrelid = 'public.categorias'::regclass
    ) THEN
        ALTER TABLE public.categorias
            ADD CONSTRAINT categorias_modo_reposicao_padrao_check
            CHECK (
                modo_reposicao_padrao IS NULL
                OR modo_reposicao_padrao IN ('VOLUME', 'META_DIA')
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'categorias_dias_contagem_padrao_check'
          AND conrelid = 'public.categorias'::regclass
    ) THEN
        ALTER TABLE public.categorias
            ADD CONSTRAINT categorias_dias_contagem_padrao_check
            CHECK (
                dias_contagem_padrao IS NULL
                OR dias_contagem_padrao <@ ARRAY[1,2,3,4,5,6,7]::smallint[]
            );
    END IF;
END $$;

COMMENT ON COLUMN public.categorias.modo_reposicao_padrao IS
'Política padrão de reposição dos insumos da categoria. LOJA: VOLUME ou META_DIA. CD: sempre VOLUME.';

COMMENT ON COLUMN public.categorias.dias_contagem_padrao IS
'Dias padrão de contagem da categoria. 1=segunda ... 7=domingo. O contexto do insumo pode sobrescrever este valor.';

COMMENT ON COLUMN public.categorias.ativo_contagem IS
'Define se a categoria participa da rotina de contagem.';

-- =========================================================
-- 2. PREENCHER CATEGORIAS EXISTENTES
-- =========================================================

WITH politica(id, modo_reposicao_padrao, dias_contagem_padrao, ativo_contagem) AS (
    VALUES
        ('05143b78-4a44-44d3-8b91-bff38f3fb8ef'::uuid, 'META_DIA', '{1,2,3,4,5,6,7}'::smallint[], true),
        ('09585f6d-6968-4a21-aef4-474b280cc268'::uuid, 'VOLUME', '{1,5}'::smallint[], true),
        ('114b126c-b7f7-43eb-852c-dcac113906bf'::uuid, 'META_DIA', '{1,2,3,4,5,6,7}'::smallint[], true),
        ('27ca8800-0a2b-44dd-a454-e31a0479efa9'::uuid, 'VOLUME', '{2}'::smallint[], true),
        ('2f368d0a-9855-4d29-b58f-2f84e35b20ad'::uuid, 'META_DIA', '{1,2,3,4,5,6,7}'::smallint[], true),
        ('312ef3fc-ba4f-4a98-b267-21c2f3597afc'::uuid, 'VOLUME', '{2}'::smallint[], true),
        ('3abf89d9-388b-446c-a52f-8fea5d16e47b'::uuid, 'VOLUME', '{1,5}'::smallint[], true),
        ('4520c70e-28b9-4c17-96c1-dd0fc98b8b27'::uuid, 'VOLUME', '{1,5}'::smallint[], true),
        ('55009c94-4b66-4612-a358-1b7f461cb787'::uuid, 'VOLUME', '{1}'::smallint[], true),
        ('5e2cd90a-2bb7-406e-b572-1445acd5ce10'::uuid, 'META_DIA', '{1,2,3,4,5,6,7}'::smallint[], true),
        ('5e3679d4-280f-47b4-81a7-d308295dbd8e'::uuid, 'META_DIA', '{1,2,3,4,5,6,7}'::smallint[], true),
        ('65013851-035c-4534-9b58-a128bfae3477'::uuid, 'META_DIA', '{1,2,3,4,5,6,7}'::smallint[], true),
        ('664fca14-4561-464a-9ab0-dbfd44bd5a91'::uuid, 'VOLUME', '{1,5}'::smallint[], true),
        ('6ea62014-33da-4777-b740-87707f936b0f'::uuid, 'VOLUME', '{1,5}'::smallint[], true),
        ('73ea9102-d031-405f-a38c-a39cd0447838'::uuid, 'META_DIA', '{1,2,3,4,5,6,7}'::smallint[], true),
        ('85ee623e-929b-4e86-9ff8-971a07daeac2'::uuid, 'META_DIA', '{1,2,3,4,5,6,7}'::smallint[], true),
        ('8715af09-16c4-4931-aa40-947b844a6f8b'::uuid, 'META_DIA', '{1,2,3,4,5,6,7}'::smallint[], true),
        ('8c01673d-d3a1-4c92-8516-264b4052bf5c'::uuid, 'VOLUME', '{1,5}'::smallint[], true),
        ('8e77cf8b-ad4b-416d-84c4-72c8ce59b33e'::uuid, 'VOLUME', '{7}'::smallint[], true),
        ('9a04cee4-e43a-49f8-91e6-9a9159b15b64'::uuid, 'VOLUME', '{1,5}'::smallint[], true),
        ('a585690b-be1a-4ef9-bd1d-d44d08dcccf2'::uuid, 'VOLUME', '{1,5}'::smallint[], true),
        ('a749c078-3b5d-41a9-891b-1f8763694021'::uuid, 'VOLUME', '{1}'::smallint[], true),
        ('a9724f82-3d74-4229-b8b6-5733b8e11725'::uuid, 'META_DIA', '{1,2,3,4,5,6,7}'::smallint[], true),
        ('aaaac0d2-9c1e-4a83-8ade-73ace3667da5'::uuid, 'VOLUME', '{1,5}'::smallint[], true),
        ('b4f26c12-7e16-4de6-bd0b-0fd88ff385a2'::uuid, 'VOLUME', '{1}'::smallint[], true),
        ('bd98bdf1-90a2-4813-b08f-ad60db795557'::uuid, 'VOLUME', '{1,5}'::smallint[], true),
        ('bf78d7d8-07a6-4200-bf94-e95da4a548b2'::uuid, 'META_DIA', '{1,2,3,4,5,6,7}'::smallint[], true),
        ('c7469903-ba67-4e42-a528-f617bb359043'::uuid, 'VOLUME', '{1}'::smallint[], true),
        ('c9528fa3-102d-4657-9803-1b76cb0016c3'::uuid, 'META_DIA', '{1,2,3,4,5,6,7}'::smallint[], true),
        ('d037f70d-299b-499e-9bca-1abdaa007aa5'::uuid, 'META_DIA', '{7}'::smallint[], true),
        ('d5053a9f-1186-4add-9110-ad04af3056b4'::uuid, 'VOLUME', '{1}'::smallint[], true),
        ('d733d42b-c706-4d21-9c35-4f01b642a1a2'::uuid, 'META_DIA', '{1,2,3,4,5,6,7}'::smallint[], true),
        ('dc57bcf5-1981-425d-8a28-87b155935766'::uuid, 'META_DIA', '{1,2,3,4,5,6,7}'::smallint[], true),
        ('ddf21321-ed4c-4924-91d9-bcb74958087d'::uuid, 'VOLUME', '{1,5}'::smallint[], true),
        ('e211107c-65a5-4c7c-85b8-0ed559cd28a5'::uuid, 'VOLUME', '{1}'::smallint[], true),
        ('e4f9f8c8-9e73-4040-98ea-1ceb78a16017'::uuid, 'VOLUME', '{1}'::smallint[], true),
        ('f56de9d9-954b-4568-9bbf-d26b1aa7b69c'::uuid, 'VOLUME', '{4}'::smallint[], true),
        ('fc69ad17-4ebb-4fb5-8db3-2879cedf35bb'::uuid, 'META_DIA', '{1,2,3,4,5,6,7}'::smallint[], true),
        ('ffe74496-0684-471c-b252-bf439e2eb519'::uuid, 'VOLUME', '{1,5}'::smallint[], true)
)
UPDATE public.categorias c
SET
    modo_reposicao_padrao = p.modo_reposicao_padrao,
    dias_contagem_padrao = p.dias_contagem_padrao,
    ativo_contagem = p.ativo_contagem
FROM politica p
WHERE c.id = p.id;

-- =========================================================
-- 3. CRIAR CATEGORIA CIGARROS / CD
-- =========================================================

INSERT INTO public.categorias (
    nome,
    setor,
    destino_padrao,
    tipo,
    setor_padrao,
    contagem_diaria,
    modo_reposicao_padrao,
    dias_contagem_padrao,
    ativo_contagem
)
SELECT
    'CIGARROS',
    'CD',
    'REPOSICAO',
    'CD',
    'CD',
    true,
    'VOLUME',
    ARRAY[3]::smallint[],
    true
WHERE NOT EXISTS (
    SELECT 1
    FROM public.categorias
    WHERE nome = 'CIGARROS'
      AND tipo = 'CD'
);

COMMIT;
