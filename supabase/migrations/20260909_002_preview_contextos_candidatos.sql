-- AlvimOS
-- CHANGE-002A — Fase B1 (CORRIGIDO)
-- Preview SOMENTE LEITURA dos contextos candidatos.
-- Não insere, atualiza ou remove dados persistentes.
--
-- Observação:
-- Em PostgreSQL, um CTE (WITH ...) só existe para a instrução SELECT
-- imediatamente seguinte. Por isso o bloco base/diagnostico é repetido
-- antes de cada consulta que depende dele.

-- =========================================================
-- 1) RESUMO GERAL
-- =========================================================
WITH base AS (
  SELECT
    i.id,
    i.nome,
    i.produzido_internamente,
    i.recebido_no_cd,
    i.enviado_loja,
    i.categoria_cd,
    i.categoria_loja,
    i.gatilho_pedido,
    i.estoque_ideal,
    i.compra_diaria,
    (i.produzido_internamente = true OR i.recebido_no_cd = true) AS espera_contexto_cd,
    (i.enviado_loja = true) AS espera_contexto_loja
  FROM public.insumos i
),
diagnostico AS (
  SELECT
    b.*,
    CASE
      WHEN b.espera_contexto_cd AND NULLIF(TRIM(b.categoria_cd), '') IS NULL
        THEN true ELSE false
    END AS problema_cd_sem_categoria,
    CASE
      WHEN b.espera_contexto_loja AND NULLIF(TRIM(b.categoria_loja), '') IS NULL
        THEN true ELSE false
    END AS problema_loja_sem_categoria,
    CASE
      WHEN NOT b.espera_contexto_cd AND NULLIF(TRIM(b.categoria_cd), '') IS NOT NULL
        THEN true ELSE false
    END AS categoria_cd_sem_contexto_esperado,
    CASE
      WHEN NOT b.espera_contexto_loja AND NULLIF(TRIM(b.categoria_loja), '') IS NOT NULL
        THEN true ELSE false
    END AS categoria_loja_sem_contexto_esperado
  FROM base b
)
SELECT
  COUNT(*) AS total_insumos,
  COUNT(*) FILTER (WHERE espera_contexto_cd) AS candidatos_cd,
  COUNT(*) FILTER (WHERE espera_contexto_loja) AS candidatos_loja,
  COUNT(*) FILTER (WHERE espera_contexto_cd AND espera_contexto_loja) AS candidatos_cd_e_loja,
  COUNT(*) FILTER (WHERE problema_cd_sem_categoria) AS cd_sem_categoria,
  COUNT(*) FILTER (WHERE problema_loja_sem_categoria) AS loja_sem_categoria,
  COUNT(*) FILTER (WHERE categoria_cd_sem_contexto_esperado) AS categoria_cd_sem_contexto,
  COUNT(*) FILTER (WHERE categoria_loja_sem_contexto_esperado) AS categoria_loja_sem_contexto
FROM diagnostico;

-- =========================================================
-- 2) LISTA COMPLETA DOS CANDIDATOS
-- =========================================================
WITH base AS (
  SELECT
    i.id,
    i.nome,
    i.produzido_internamente,
    i.recebido_no_cd,
    i.enviado_loja,
    i.categoria_cd,
    i.categoria_loja,
    i.gatilho_pedido,
    i.estoque_ideal,
    i.compra_diaria,
    (i.produzido_internamente = true OR i.recebido_no_cd = true) AS espera_contexto_cd,
    (i.enviado_loja = true) AS espera_contexto_loja
  FROM public.insumos i
),
diagnostico AS (
  SELECT
    b.*,
    CASE
      WHEN b.espera_contexto_cd AND NULLIF(TRIM(b.categoria_cd), '') IS NULL
        THEN true ELSE false
    END AS problema_cd_sem_categoria,
    CASE
      WHEN b.espera_contexto_loja AND NULLIF(TRIM(b.categoria_loja), '') IS NULL
        THEN true ELSE false
    END AS problema_loja_sem_categoria,
    CASE
      WHEN NOT b.espera_contexto_cd AND NULLIF(TRIM(b.categoria_cd), '') IS NOT NULL
        THEN true ELSE false
    END AS categoria_cd_sem_contexto_esperado,
    CASE
      WHEN NOT b.espera_contexto_loja AND NULLIF(TRIM(b.categoria_loja), '') IS NOT NULL
        THEN true ELSE false
    END AS categoria_loja_sem_contexto_esperado
  FROM base b
)
SELECT
  id,
  nome,
  produzido_internamente,
  recebido_no_cd AS recebido_externamente_no_cd_atual,
  enviado_loja AS controlado_na_loja_atual,
  espera_contexto_cd,
  espera_contexto_loja,
  categoria_cd,
  categoria_loja,
  gatilho_pedido,
  estoque_ideal,
  compra_diaria,
  problema_cd_sem_categoria,
  problema_loja_sem_categoria,
  categoria_cd_sem_contexto_esperado,
  categoria_loja_sem_contexto_esperado
FROM diagnostico
ORDER BY nome;

-- =========================================================
-- 3) SOMENTE INCONSISTÊNCIAS
-- =========================================================
WITH base AS (
  SELECT
    i.id,
    i.nome,
    i.produzido_internamente,
    i.recebido_no_cd,
    i.enviado_loja,
    i.categoria_cd,
    i.categoria_loja,
    (i.produzido_internamente = true OR i.recebido_no_cd = true) AS espera_contexto_cd,
    (i.enviado_loja = true) AS espera_contexto_loja
  FROM public.insumos i
),
diagnostico AS (
  SELECT
    b.*,
    CASE
      WHEN b.espera_contexto_cd AND NULLIF(TRIM(b.categoria_cd), '') IS NULL
        THEN true ELSE false
    END AS problema_cd_sem_categoria,
    CASE
      WHEN b.espera_contexto_loja AND NULLIF(TRIM(b.categoria_loja), '') IS NULL
        THEN true ELSE false
    END AS problema_loja_sem_categoria,
    CASE
      WHEN NOT b.espera_contexto_cd AND NULLIF(TRIM(b.categoria_cd), '') IS NOT NULL
        THEN true ELSE false
    END AS categoria_cd_sem_contexto_esperado,
    CASE
      WHEN NOT b.espera_contexto_loja AND NULLIF(TRIM(b.categoria_loja), '') IS NOT NULL
        THEN true ELSE false
    END AS categoria_loja_sem_contexto_esperado
  FROM base b
)
SELECT
  id,
  nome,
  produzido_internamente,
  recebido_no_cd,
  enviado_loja,
  categoria_cd,
  categoria_loja,
  problema_cd_sem_categoria,
  problema_loja_sem_categoria,
  categoria_cd_sem_contexto_esperado,
  categoria_loja_sem_contexto_esperado
FROM diagnostico
WHERE
  problema_cd_sem_categoria
  OR problema_loja_sem_categoria
  OR categoria_cd_sem_contexto_esperado
  OR categoria_loja_sem_contexto_esperado
ORDER BY nome;

-- =========================================================
-- 4) PRODUZIDOS INTERNAMENTE
-- =========================================================
SELECT
  id,
  nome,
  produzido_internamente,
  recebido_no_cd,
  enviado_loja,
  categoria_cd,
  categoria_loja
FROM public.insumos
WHERE produzido_internamente = true
ORDER BY nome;

-- =========================================================
-- 5) ITENS COMPRADOS EXTERNAMENTE E CONTROLADOS NA LOJA,
--    SEM RECEBIMENTO NO CD
-- =========================================================
SELECT
  id,
  nome,
  categoria_loja,
  gatilho_pedido,
  estoque_ideal,
  compra_diaria
FROM public.insumos
WHERE produzido_internamente = false
  AND recebido_no_cd = false
  AND enviado_loja = true
ORDER BY nome;

