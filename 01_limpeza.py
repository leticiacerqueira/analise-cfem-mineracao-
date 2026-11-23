"""Projeto 1 - CFEM: limpeza e padronização da base de arrecadação.
Entrada: CFEM_Arrecadacao_simulada.csv (layout da ANM, ';' e decimal ',', cp1252)
Saída: cfem_limpo.csv + cfem.db (SQLite para as consultas em SQL)
"""
import sqlite3, unicodedata
import pandas as pd

ENTRADA = "CFEM_Arrecadacao_simulada.csv"
df = pd.read_csv(ENTRADA, sep=";", decimal=",", encoding="cp1252")
log = {"linhas_brutas": len(df)}

# 1. Nomes de colunas sem acento, em snake_case
def sem_acento(s):
    return unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
df.columns = [sem_acento(c).lower() for c in df.columns]
df = df.rename(columns={"tipo_pf_pj": "tipo_pessoa", "cpf_cnpj": "documento",
                        "anodoprocesso": "ano_processo",
                        "quantidadecomercializada": "quantidade",
                        "unidadedemedida": "unidade", "valorrecolhido": "valor_recolhido"})

# 2. Padronizar substância: espaços, caixa e acentos ("Minério de Ferro", " MINERIO DE FERRO")
mapa = {"MINERIO DE FERRO": "MINÉRIO DE FERRO", "AGUA MINERAL": "ÁGUA MINERAL",
        "NIOBIO": "NIÓBIO", "NIQUEL": "NÍQUEL"}
original = df["substancia"].copy()
chave = original.str.strip().str.upper().map(sem_acento)
df["substancia"] = chave.map(mapa).fillna(original.str.strip().str.upper())
log["grafias_corrigidas"] = int((original != df["substancia"]).sum())

# 3. Remover linhas duplicadas
dup = df.duplicated().sum()
df = df.drop_duplicates()
log["duplicadas_removidas"] = int(dup)

# 4. Quantidade vazia: manter a linha (o valor recolhido existe), marcar com flag
df["quantidade_informada"] = df["quantidade"].notna()
log["quantidades_vazias"] = int((~df["quantidade_informada"]).sum())

# 5. Coluna de data para séries mensais
df["data"] = pd.to_datetime(dict(year=df["ano"], month=df["mes"], day=1))

df.to_csv("cfem_limpo.csv", index=False, encoding="utf-8")
with sqlite3.connect("cfem.db") as con:
    df.assign(data=df["data"].dt.strftime("%Y-%m-%d")).to_sql("cfem", con, if_exists="replace", index=False)

log["linhas_finais"] = len(df)
log["substancias_distintas"] = df["substancia"].nunique()
print(log)
