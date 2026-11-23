# Para onde vão os royalties da mineração? Análise da CFEM

**Pergunta de negócio:** quais substâncias, estados e municípios concentram a arrecadação da CFEM, e como ela varia ao longo do ano?

A CFEM (Compensação Financeira pela Exploração de Recursos Minerais) é o royalty que as mineradoras pagam sobre o faturamento. Este projeto limpa uma base de arrecadação no formato dos dados abertos da ANM, carrega em SQLite e responde às perguntas com SQL.

> **Sobre os dados:** a base é **simulada**, com o mesmo layout do arquivo `CFEM_Arrecadacao.csv` da ANM (2019 a set/2025), e inclui de propósito os problemas comuns desse arquivo. Os valores demonstram o método e não são números oficiais.

Portfólio: https://leticiacerqueira.github.io

## Ferramentas
Python (pandas) · SQL (SQLite: CTEs e window functions) · Power BI (próxima etapa)

## Etapas
1. **Limpeza em Python** (`01_limpeza.py`): leitura no padrão brasileiro (`;`, vírgula decimal, cp1252), nomes de colunas em snake_case, padronização de grafias de substância, remoção de duplicadas, flag para registros sem quantidade e coluna de data mensal.
2. **Carga em SQLite** (`cfem.db`, tabela `cfem`).
3. **Perguntas em SQL** (`02_consultas.sql`): variação anual com `LAG`, Pareto com soma acumulada, top 3 municípios por estado com `RANK`, R$ por unidade, média móvel de 3 meses e checagem de qualidade.

| Etapa de qualidade | Registros |
|---|---:|
| Linhas no arquivo bruto | 6.705 |
| Grafias de substância corrigidas | 248 |
| Duplicadas removidas | 25 |
| Sem quantidade (mantidos e marcados, 1,1% do valor) | 73 |
| Linhas na base final | 6.680 |

## Resultados
- Minério de ferro responde por **87,9%** da arrecadação. Com o cobre, chega a **94,4%**.
- O Pará concentra **71,7%** do total. Parauapebas e Canaã dos Carajás somam **66,6%**.
- Pico em 2021 (+46,6% sobre 2020) e queda de 26% até 2024, acompanhando o ciclo de preço do minério.
- Janeiro e fevereiro são os meses mais fracos. De julho a setembro a média é cerca de 39% maior.

## Como rodar
```bash
pip install pandas
python 01_limpeza.py          # gera cfem_limpo.csv e cfem.db
sqlite3 cfem.db < 02_consultas.sql
```

## Autora
Leticia Santos Cerqueira · Analista de Dados e BI · [LinkedIn](https://www.linkedin.com/in/leticiasantoscerqueira/)
