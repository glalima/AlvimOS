-- AlvimOS
-- CHANGE-002A — Fase B3
-- Diagnóstico por categoria da Loja.
-- SOMENTE LEITURA.
-- Não altera dados.

WITH base AS (
    SELECT
        i.id AS insumo_id,
        i.nome,
        i.categoria_loja,
        i.compra_diaria,
        ic.estoque_gatilho,
        ic.estoque_ideal,
        EXISTS (
            SELECT 1
            FROM public.meta_estoque m
            WHERE m.id_insumo = i.id
        ) AS tem_meta_historica
    FROM public.insumo_contexto_estoque ic
    JOIN public.insumos i
      ON i.id = ic.insumo_id
    WHERE ic.local = 'LOJA'
)
SELECT
    COALESCE(NULLIF(TRIM(categoria_loja), ''), 'SEM CATEGORIA') AS categoria_loja,
    COUNT(*) AS total_itens,

    COUNT(*) FILTER (
        WHERE tem_meta_historica = true
    ) AS com_meta_historica,

    COUNT(*) FILTER (
        WHERE COALESCE(estoque_gatilho, 0) > 0
           OR COALESCE(estoque_ideal, 0) > 0
    ) AS com_volume_parametrizado,

    COUNT(*) FILTER (
        WHERE COALESCE(estoque_gatilho, 0) = 0
          AND COALESCE(estoque_ideal, 0) = 0
    ) AS com_zero_zero,

    COUNT(*) FILTER (
        WHERE compra_diaria = true
    ) AS legado_compra_diaria_true,

    COUNT(*) FILTER (
        WHERE compra_diaria = false
    ) AS legado_compra_diaria_false,

    ROUND(
        100.0 * COUNT(*) FILTER (WHERE tem_meta_historica = true)
        / NULLIF(COUNT(*), 0),
        1
    ) AS percentual_com_meta_historica,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE COALESCE(estoque_gatilho, 0) > 0
               OR COALESCE(estoque_ideal, 0) > 0
        )
        / NULLIF(COUNT(*), 0),
        1
    ) AS percentual_com_volume_parametrizado

FROM base
GROUP BY COALESCE(NULLIF(TRIM(categoria_loja), ''), 'SEM CATEGORIA')
ORDER BY categoria_loja;

-- Detalhe por item, para usar somente depois de definir o padrão da categoria.
SELECT
    i.id,
    i.nome,
    i.categoria_loja,
    ic.estoque_gatilho,
    ic.estoque_ideal,
    i.compra_diaria AS legado_compra_diaria,
    EXISTS (
        SELECT 1
        FROM public.meta_estoque m
        WHERE m.id_insumo = i.id
    ) AS tem_meta_historica
FROM public.insumo_contexto_estoque ic
JOIN public.insumos i
  ON i.id = ic.insumo_id
WHERE ic.local = 'LOJA'
ORDER BY i.categoria_loja, i.nome;
