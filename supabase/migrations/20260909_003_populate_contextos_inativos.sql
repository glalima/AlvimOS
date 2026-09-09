-- AlvimOS
-- CHANGE-002A — Fase B2
-- Popula contextos em coexistência com o modelo legado.
-- Todos permanecem ativo=false.
-- Aceita gatilho/ideal = 0/0.
-- Não migra metas ainda.

BEGIN;

INSERT INTO public.insumo_contexto_estoque (
    insumo_id, local, categoria_id, dias_contagem_override,
    modo_reposicao_loja, estoque_gatilho, estoque_ideal, ativo
)
SELECT
    i.id,
    'CD',
    c.id,
    NULL::smallint[],
    NULL::text,
    COALESCE(i.gatilho_pedido, 0),
    COALESCE(i.estoque_ideal, 0),
    false
FROM public.insumos i
LEFT JOIN public.categorias c ON c.nome = i.categoria_cd
WHERE i.produzido_internamente = true
   OR i.recebido_no_cd = true
ON CONFLICT (insumo_id, local)
DO UPDATE SET
    categoria_id = EXCLUDED.categoria_id,
    estoque_gatilho = EXCLUDED.estoque_gatilho,
    estoque_ideal = EXCLUDED.estoque_ideal,
    updated_at = now();

INSERT INTO public.insumo_contexto_estoque (
    insumo_id, local, categoria_id, dias_contagem_override,
    modo_reposicao_loja, estoque_gatilho, estoque_ideal, ativo
)
SELECT
    i.id,
    'LOJA',
    c.id,
    NULL::smallint[],
    NULL::text,
    COALESCE(i.gatilho_pedido, 0),
    COALESCE(i.estoque_ideal, 0),
    false
FROM public.insumos i
LEFT JOIN public.categorias c ON c.nome = i.categoria_loja
WHERE i.enviado_loja = true
ON CONFLICT (insumo_id, local)
DO UPDATE SET
    categoria_id = EXCLUDED.categoria_id,
    estoque_gatilho = EXCLUDED.estoque_gatilho,
    estoque_ideal = EXCLUDED.estoque_ideal,
    updated_at = now();

COMMIT;

-- VALIDAÇÃO A: totais por local
SELECT
    local,
    COUNT(*) AS total_contextos,
    COUNT(*) FILTER (WHERE categoria_id IS NULL) AS sem_categoria,
    COUNT(*) FILTER (
        WHERE COALESCE(estoque_gatilho, 0) = 0
          AND COALESCE(estoque_ideal, 0) = 0
    ) AS com_zero_zero,
    COUNT(*) FILTER (WHERE ativo = true) AS ativos
FROM public.insumo_contexto_estoque
GROUP BY local
ORDER BY local;

-- VALIDAÇÃO B: esperado x criado
WITH esperado AS (
    SELECT
        COUNT(*) FILTER (
            WHERE produzido_internamente = true OR recebido_no_cd = true
        ) AS esperado_cd,
        COUNT(*) FILTER (WHERE enviado_loja = true) AS esperado_loja
    FROM public.insumos
),
criado AS (
    SELECT
        COUNT(*) FILTER (WHERE local = 'CD') AS criado_cd,
        COUNT(*) FILTER (WHERE local = 'LOJA') AS criado_loja
    FROM public.insumo_contexto_estoque
)
SELECT * FROM esperado CROSS JOIN criado;

-- VALIDAÇÃO C: produzidos internamente + Loja devem ter CD e LOJA
SELECT
    i.id,
    i.nome,
    COUNT(ic.id) AS qtd_contextos,
    STRING_AGG(ic.local, ', ' ORDER BY ic.local) AS locais
FROM public.insumos i
LEFT JOIN public.insumo_contexto_estoque ic ON ic.insumo_id = i.id
WHERE i.produzido_internamente = true
  AND i.enviado_loja = true
GROUP BY i.id, i.nome
ORDER BY i.nome;

-- VALIDAÇÃO D: contextos sem categoria
SELECT
    ic.id AS contexto_id,
    i.nome,
    ic.local,
    i.categoria_cd,
    i.categoria_loja
FROM public.insumo_contexto_estoque ic
JOIN public.insumos i ON i.id = ic.insumo_id
WHERE ic.categoria_id IS NULL
ORDER BY ic.local, i.nome;

-- VALIDAÇÃO E: 0/0 por local e categoria
SELECT
    ic.local,
    COALESCE(c.nome, 'SEM CATEGORIA') AS categoria,
    COUNT(*) AS total_zero_zero
FROM public.insumo_contexto_estoque ic
LEFT JOIN public.categorias c ON c.id = ic.categoria_id
WHERE COALESCE(ic.estoque_gatilho, 0) = 0
  AND COALESCE(ic.estoque_ideal, 0) = 0
GROUP BY ic.local, COALESCE(c.nome, 'SEM CATEGORIA')
ORDER BY ic.local, total_zero_zero DESC, categoria;
