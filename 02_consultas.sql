-- Projeto 1 - CFEM: perguntas de negócio em SQL (SQLite)
-- Tabela: cfem (gerada por 01_limpeza.py)

-- Q1. Quanto se arrecadou por ano e qual foi a variação em relação ao ano anterior?
WITH anual AS (
  SELECT ano, SUM(valor_recolhido) AS total
  FROM cfem
  WHERE ano < 2025                      -- 2025 vai só até setembro
  GROUP BY ano
)
SELECT ano,
       ROUND(total / 1e6, 1) AS total_milhoes,
       ROUND(100.0 * (total - LAG(total) OVER (ORDER BY ano))
             / LAG(total) OVER (ORDER BY ano), 1) AS variacao_pct
FROM anual
ORDER BY ano;

-- Q2. Quais substâncias concentram a arrecadação? (participação e acumulado, estilo Pareto)
WITH por_subst AS (
  SELECT substancia, SUM(valor_recolhido) AS total
  FROM cfem GROUP BY substancia
)
SELECT substancia,
       ROUND(total / 1e6, 1) AS total_milhoes,
       ROUND(100.0 * total / SUM(total) OVER (), 1) AS part_pct,
       ROUND(100.0 * SUM(total) OVER (ORDER BY total DESC)
             / SUM(total) OVER (), 1) AS acumulado_pct
FROM por_subst
ORDER BY total DESC;

-- Q3. Top 3 municípios arrecadadores em cada estado
WITH mun AS (
  SELECT uf, municipio, SUM(valor_recolhido) AS total
  FROM cfem GROUP BY uf, municipio
), ranqueado AS (
  SELECT *, RANK() OVER (PARTITION BY uf ORDER BY total DESC) AS posicao
  FROM mun
)
SELECT uf, posicao, municipio, ROUND(total / 1e6, 1) AS total_milhoes
FROM ranqueado
WHERE posicao <= 3
ORDER BY uf, posicao;

-- Q4. Valor médio recolhido por unidade comercializada (R$/unidade), por substância
--     Linhas sem quantidade informada ficam fora do cálculo.
SELECT substancia, unidade,
       ROUND(SUM(valor_recolhido) / SUM(quantidade), 2) AS reais_por_unidade,
       COUNT(*) AS registros
FROM cfem
WHERE quantidade_informada = 1
GROUP BY substancia, unidade
ORDER BY substancia;

-- Q5. Sazonalidade: média móvel de 3 meses da arrecadação total
WITH mensal AS (
  SELECT data, SUM(valor_recolhido) AS total
  FROM cfem GROUP BY data
)
SELECT data,
       ROUND(total / 1e6, 1) AS total_milhoes,
       ROUND(AVG(total) OVER (ORDER BY data ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) / 1e6, 1)
         AS media_movel_3m
FROM mensal
ORDER BY data;

-- Q6. Qualidade dos dados: quanto do valor vem de registros sem quantidade informada?
SELECT quantidade_informada,
       COUNT(*) AS registros,
       ROUND(100.0 * SUM(valor_recolhido) / (SELECT SUM(valor_recolhido) FROM cfem), 2) AS pct_valor
FROM cfem
GROUP BY quantidade_informada;
