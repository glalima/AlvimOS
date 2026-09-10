-- AlvimOS
-- CHANGE-002A — Fase B4
-- Correção final de itens entregues diretamente na Loja
-- Data: 2026-09-09

BEGIN;

-- 1. Corrigir a origem logística no cadastro legado
UPDATE public.insumos
SET
    recebido_no_cd = false,
    categoria_cd = NULL
WHERE id IN (
    'bff5b9b6-064e-48c9-97cb-12ad6b398bae', -- Heineken LN
    '8c1aef26-8b4e-48be-8695-60e6629903ea', -- Coca 600ml
    'cd1e6b8e-f00b-4cc7-af50-cad79adeea09'  -- Fruki 600ml
);

-- 2. Remover somente o contexto CD indevido
DELETE FROM public.insumo_contexto_estoque
WHERE local = 'CD'
  AND insumo_id IN (
    'bff5b9b6-064e-48c9-97cb-12ad6b398bae',
    '8c1aef26-8b4e-48be-8695-60e6629903ea',
    'cd1e6b8e-f00b-4cc7-af50-cad79adeea09'
  );

COMMIT;


-- =========================================================
-- VALIDAÇÃO
-- =========================================================

-- Os 3 devem aparecer somente com contexto LOJA
SELECT
    i.nome,
    i.produzido_internamente,
    i.recebido_no_cd,
    i.enviado_loja,
    i.categoria_cd,
    STRING_AGG(ic.local, ', ' ORDER BY ic.local) AS contextos
FROM public.insumos i
LEFT JOIN public.insumo_contexto_estoque ic
    ON ic.insumo_id = i.id
WHERE i.id IN (
    'bff5b9b6-064e-48c9-97cb-12ad6b398bae',
    '8c1aef26-8b4e-48be-8695-60e6629903ea',
    'cd1e6b8e-f00b-4cc7-af50-cad79adeea09'
)
GROUP BY
    i.id,
    i.nome,
    i.produzido_internamente,
    i.recebido_no_cd,
    i.enviado_loja,
    i.categoria_cd
ORDER BY i.nome;

-- Compatibilidade geral: esperado zero categorias incompatíveis
SELECT
    ic.local,
    COUNT(*) AS total_contextos,
    COUNT(*) FILTER (WHERE c.id IS NULL) AS sem_categoria,
    COUNT(*) FILTER (
        WHERE c.id IS NOT NULL
          AND c.tipo = ic.local
    ) AS categoria_local_ok,
    COUNT(*) FILTER (
        WHERE c.id IS NOT NULL
          AND c.tipo IS DISTINCT FROM ic.local
    ) AS categoria_local_incorreta
FROM public.insumo_contexto_estoque ic
LEFT JOIN public.categorias c
    ON c.id = ic.categoria_id
GROUP BY ic.local
ORDER BY ic.local;
