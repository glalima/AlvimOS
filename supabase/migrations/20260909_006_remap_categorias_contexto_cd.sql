-- AlvimOS
-- CHANGE-002A — Fase B4
-- Remapeamento de categoria_id dos contextos CD
-- Fonte: mapeamento manual aprovado em 09/09/2026
--
-- IMPORTANTE:
-- Esta migration remapeia APENAS categorias com destino CD explícito.
-- Casos marcados como "não tem no CD" NÃO são apagados nem alterados aqui.
-- Eles serão listados ao final para revisão estrutural do contexto/booleanas.
--
-- O objetivo é evitar excluir contexto CD automaticamente quando a origem do
-- problema pode estar em recebido_no_cd / produzido_internamente legados.

BEGIN;

-- =========================================================
-- 1. MAPA DE CONVERSÃO APROVADO
-- origem = nome legado usado no contexto CD / categoria_cd
-- destino = categoria oficial tipo='CD'
-- =========================================================

WITH mapa(origem, destino) AS (
    VALUES
        ('2 - Hortifruti', 'Refrigerados & Laticínios'),
        ('4 - Cremes', 'Secos & Mercearia'),
        ('Salgadinhos', 'Secos & Mercearia'),
        ('1 - Freezer', 'Congelados & Freezer'),
        ('Doces', 'Chocolates & Guloseimas'),
        ('5 - Embalagens', 'Embalagens Master & Caixas'),
        ('9 - Diversos', 'Químicos & Limpeza Pesada'),
        ('3 - Marmitas', 'Refrigerados & Laticínios'),
        ('8 - Embalagens - açaí', 'Embalagens Master & Caixas'),
        ('7 - Refrigerados', 'Refrigerados & Laticínios'),
        ('6 - Secos e condimentos', 'Secos & Mercearia'),
        ('3 - Copos', 'Embalagens Master & Caixas'),
        ('2 - Tampas', 'Embalagens Master & Caixas'),
        ('5 - Secos', 'Secos & Mercearia'),
        ('4 - Geladeira', 'Refrigerados & Laticínios'),
        ('Cigarros', 'CIGARROS')
),
destinos AS (
    SELECT
        m.origem,
        m.destino,
        c.id AS categoria_destino_id
    FROM mapa m
    JOIN public.categorias c
      ON c.nome = m.destino
     AND c.tipo = 'CD'
)
UPDATE public.insumo_contexto_estoque ic
SET
    categoria_id = d.categoria_destino_id,
    updated_at = now()
FROM public.insumos i
JOIN destinos d
  ON d.origem = i.categoria_cd
WHERE ic.insumo_id = i.id
  AND ic.local = 'CD';

COMMIT;

-- =========================================================
-- 2. VALIDAÇÃO DO REMAPEAMENTO
-- =========================================================

-- A. Resumo geral após o update
SELECT
    ic.local,
    COUNT(*) AS total_contextos,
    COUNT(*) FILTER (
        WHERE c.id IS NULL
    ) AS sem_categoria,
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

-- B. Restantes incompatíveis no CD
-- Esperado: principalmente itens cuja categoria legada foi marcada
-- manualmente como "não tem no CD".
SELECT
    ic.id AS contexto_id,
    i.id AS insumo_id,
    i.nome AS insumo,
    i.produzido_internamente,
    i.recebido_no_cd,
    i.enviado_loja,
    i.categoria_cd AS categoria_cd_legada,
    c.nome AS categoria_atual,
    c.tipo AS tipo_categoria_atual
FROM public.insumo_contexto_estoque ic
JOIN public.insumos i
  ON i.id = ic.insumo_id
LEFT JOIN public.categorias c
  ON c.id = ic.categoria_id
WHERE ic.local = 'CD'
  AND (c.id IS NULL OR c.tipo IS DISTINCT FROM 'CD')
ORDER BY i.categoria_cd, i.nome;

-- C. Resumo dos restantes por categoria legada
SELECT
    COALESCE(NULLIF(TRIM(i.categoria_cd), ''), 'SEM categoria_cd') AS categoria_cd_legada,
    COUNT(*) AS total_contextos_restantes,
    COUNT(*) FILTER (WHERE i.produzido_internamente = true) AS produzidos_internamente,
    COUNT(*) FILTER (WHERE i.recebido_no_cd = true) AS recebidos_no_cd
FROM public.insumo_contexto_estoque ic
JOIN public.insumos i
  ON i.id = ic.insumo_id
LEFT JOIN public.categorias c
  ON c.id = ic.categoria_id
WHERE ic.local = 'CD'
  AND (c.id IS NULL OR c.tipo IS DISTINCT FROM 'CD')
GROUP BY COALESCE(NULLIF(TRIM(i.categoria_cd), ''), 'SEM categoria_cd')
ORDER BY total_contextos_restantes DESC, categoria_cd_legada;
