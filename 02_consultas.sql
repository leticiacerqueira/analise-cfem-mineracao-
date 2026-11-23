-- Projeto CFEM (dados reais da ANM, 2022 a 2026) - SQLite
-- Tabela: cfem (gerada por 01_limpeza.py)

-- Q0. Até que mês a base está completa? (registros por mês em 2026)
SELECT data, COUNT(*) AS registros
FROM cfem WHERE ano = 2026
GROUP BY data ORDER BY data;

-- Q1. Arrecadação por ano e variação sobre o ano anterior (anos completos)
WITH anual AS (
  SELECT ano, SUM(valor_recolhido) AS total
  FROM cfem WHERE ano <= 2025 GROUP BY ano
)
SELECT ano,
       ROUND(total / 1e6, 1) AS total_milhoes,
       ROUND(100.0 * (total / LAG(total) OVER (ORDER BY ano) - 1), 1) AS variacao_pct
FROM anual ORDER BY ano;

-- Q2. 1º semestre de 2026 contra o 1º semestre de 2025
SELECT ano, ROUND(SUM(valor_recolhido) / 1e6, 1) AS total_milhoes
FROM cfem WHERE mes <= 6 AND ano IN (2025, 2026)
GROUP BY ano;

-- Q3. Concentração por substância (Pareto), já com os nomes agrupados
WITH por_subst AS (
  SELECT grupo_substancia, SUM(valor_recolhido) AS total
  FROM cfem GROUP BY grupo_substancia
)
SELECT grupo_substancia,
       ROUND(total / 1e6, 1) AS total_milhoes,
       ROUND(100.0 * total / SUM(total) OVER (), 1) AS part_pct,
       ROUND(100.0 * SUM(total) OVER (ORDER BY total DESC) / SUM(total) OVER (), 1) AS acumulado_pct
FROM por_subst
ORDER BY total DESC
LIMIT 10;

-- Q4. Quais substâncias mais cresceram de 2022 para 2025? (mínimo R$ 50 mi em 2025)
WITH base AS (
  SELECT grupo_substancia,
         SUM(CASE WHEN ano = 2022 THEN valor_recolhido END) AS v2022,
         SUM(CASE WHEN ano = 2025 THEN valor_recolhido END) AS v2025
  FROM cfem GROUP BY grupo_substancia
)
SELECT grupo_substancia,
       ROUND(v2022 / 1e6, 1) AS mi_2022,
       ROUND(v2025 / 1e6, 1) AS mi_2025,
       ROUND(100.0 * (v2025 / v2022 - 1), 1) AS crescimento_pct
FROM base
WHERE v2025 >= 50e6
ORDER BY crescimento_pct DESC;

-- Q5. Top 3 municípios em cada um dos 5 estados que mais arrecadam
WITH uf_top AS (
  SELECT uf FROM cfem WHERE uf IS NOT NULL
  GROUP BY uf ORDER BY SUM(valor_recolhido) DESC LIMIT 5
), mun AS (
  SELECT uf, municipio, SUM(valor_recolhido) AS total,
         RANK() OVER (PARTITION BY uf ORDER BY SUM(valor_recolhido) DESC) AS posicao
  FROM cfem WHERE uf IN (SELECT uf FROM uf_top)
  GROUP BY uf, municipio
)
SELECT uf, posicao, municipio, ROUND(total / 1e6, 1) AS total_milhoes
FROM mun WHERE posicao <= 3
ORDER BY uf, posicao;

-- Q6. Sazonalidade: média de cada mês do ano (2022 a 2025)
WITH mensal AS (
  SELECT ano, mes, SUM(valor_recolhido) AS total
  FROM cfem WHERE ano <= 2025 GROUP BY ano, mes
)
SELECT mes, ROUND(AVG(total) / 1e6, 1) AS media_milhoes
FROM mensal GROUP BY mes ORDER BY mes;

-- Q7. Qualidade: peso dos registros com problema no valor total
SELECT 'sem UF/município' AS problema, COUNT(*) AS registros,
       ROUND(100.0 * SUM(valor_recolhido) / (SELECT SUM(valor_recolhido) FROM cfem), 3) AS pct_valor
FROM cfem WHERE sem_local = 1
UNION ALL
SELECT 'quantidade zero ou vazia', COUNT(*),
       ROUND(100.0 * SUM(valor_recolhido) / (SELECT SUM(valor_recolhido) FROM cfem), 3)
FROM cfem WHERE quantidade_valida = 0;
