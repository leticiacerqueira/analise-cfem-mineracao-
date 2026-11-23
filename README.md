# Para onde vão os royalties da mineração? Análise da CFEM 2022–2026

**Pergunta de negócio:** quais substâncias, estados e municípios concentram a arrecadação da CFEM, o que mais cresceu nos últimos anos e como 2026 se compara a 2025?

A CFEM (Compensação Financeira pela Exploração de Recursos Minerais) é o royalty que as mineradoras pagam sobre o faturamento. Este projeto usa **dados reais da Agência Nacional de Mineração (ANM)**: limpa a base em Python, carrega em SQLite e responde às perguntas com SQL.

Portfólio: https://leticiacerqueira.github.io

## Dados
- **Fonte:** Portal de Dados Abertos, conjunto [Sistema de Arrecadação da ANM](https://dados.gov.br/dados/conjuntos-dados/sistema-arrecadacao), arquivo "Arrecadação pela CFEM 2022 a 2026" (`CFEM_Arrecadacao_2022_2026.csv`, 85 MB, atualizado em 19/11/2026).
- 633.080 registros. Os lançamentos de 2026 estão completos até junho, então as comparações de 2026 usam o 1º semestre.
- O arquivo bruto não está no repositório por causa do tamanho. A pasta `resultados/` traz os agregados gerados.

## Ferramentas
Python (pandas) · SQL (SQLite: CTEs, window functions, CASE) · Power BI (próxima etapa)

## Etapas
1. **Limpeza em Python** (`01_limpeza.py`): leitura em cp1252 com vírgula decimal, remoção de espaços (a unidade vem como `"t  "`), duplicadas e agrupamento de substâncias cadastradas com nomes diferentes.
2. **Carga em SQLite** (`cfem.db`, tabela `cfem`), com flags de qualidade.
3. **Perguntas em SQL** (`02_consultas.sql`): completude de 2026, variação anual com `LAG`, 1º semestre 2026 x 2025, Pareto com soma acumulada, crescimento por substância, top 3 municípios por estado com `RANK`, sazonalidade e checagem de qualidade.

| Etapa de qualidade | Registros |
|---|---:|
| Linhas no arquivo da ANM | 633.080 |
| Duplicadas removidas | 23.771 |
| Linhas reagrupadas por nome de substância (201 nomes → 182 grupos) | 37.876 |
| Quantidade zero ou vazia (mantidas e marcadas, 0,8% do valor) | 22.929 |
| Sem UF e município (mantidas e marcadas) | 51 |
| Linhas na base final | 609.309 |

### Por que agrupar nomes importa
A ANM registra o mesmo minério como "FERRO" e "MINÉRIO DE FERRO". Separados, um parece cair 13% e o outro subir 44% entre 2022 e 2025. Somados, o ferro ficou praticamente estável (+2,4%).

| R$ milhões | 2022 | 2023 | 2024 | 2025 |
|---|---:|---:|---:|---:|
| "FERRO" | 3.875 | 3.608 | 3.732 | 3.366 |
| "MINÉRIO DE FERRO" | 1.462 | 1.524 | 1.846 | 2.099 |
| **Ferro agrupado** | **5.337** | **5.133** | **5.578** | **5.465** |

## Resultados
- A arrecadação subiu de **R$ 7,0 bi** em 2022 para **R$ 7,9 bi** em 2025 (+12,7%). O 1º semestre de 2026 está **3,8% acima** do mesmo período de 2025.
- O ferro responde por **72,5%** da arrecadação. Com cobre e ouro, chega a **84,9%**.
- De 2022 para 2025, **cobre (+102%)** e **ouro (+64%)** foram os destaques de crescimento.
- Minas Gerais (45,0%) e Pará (40,2%) somam 85%. Parauapebas e Canaã dos Carajás respondem por **32%** do país.

## Como rodar
```bash
pip install pandas
# baixe CFEM_Arrecadacao_2022_2026.csv no link da fonte acima
python 01_limpeza.py CFEM_Arrecadacao_2022_2026.csv   # gera cfem.db
sqlite3 cfem.db < 02_consultas.sql
```

## Autora
Leticia Santos Cerqueira · Analista de Dados e BI · [LinkedIn](https://www.linkedin.com/in/leticiasantoscerqueira/)
