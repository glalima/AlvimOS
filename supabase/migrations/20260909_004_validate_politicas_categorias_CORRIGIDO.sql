-- AlvimOS
-- CHANGE-002A — Fase B3
-- Validação das políticas padrão por categoria.
-- SOMENTE LEITURA.

-- A. Visão completa das políticas
SELECT
    id,
    nome,
    tipo,
    setor,
    modo_reposicao_padrao,
    dias_contagem_padrao,
    ativo_contagem
FROM public.categorias
ORDER BY tipo, nome;

-- B. Categorias sem política preenchida
SELECT
    id,
    nome,
    tipo
FROM public.categorias
WHERE modo_reposicao_padrao IS NULL
   OR dias_contagem_padrao IS NULL
ORDER BY tipo, nome;

-- C. Regra do CD: toda categoria CD deve ser VOLUME
SELECT
    id,
    nome,
    tipo,
    modo_reposicao_padrao
FROM public.categorias
WHERE tipo = 'CD'
  AND modo_reposicao_padrao IS DISTINCT FROM 'VOLUME';

-- D. Conferir Cigarros dos dois locais
SELECT
    id,
    nome,
    tipo,
    setor,
    modo_reposicao_padrao,
    dias_contagem_padrao,
    ativo_contagem
FROM public.categorias
WHERE UPPER(nome) = 'CIGARROS'
ORDER BY tipo, nome;
