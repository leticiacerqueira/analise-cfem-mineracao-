"""Projeto CFEM com dados reais da ANM: limpeza e padronização.

Entrada: CFEM_Arrecadacao_2022_2026.csv (Portal de Dados Abertos, conjunto
"sistema-arrecadacao", arquivo atualizado pela ANM em 19/11/2026).
Saída: cfem.db (SQLite, tabela cfem) e log de qualidade no terminal.
"""
import re, sqlite3, sys, unicodedata
import pandas as pd

ENTRADA = sys.argv[1] if len(sys.argv) > 1 else "CFEM_Arrecadacao_2022_2026.csv"

# 1. Leitura: separador ",", decimal ",", encoding cp1252. Tudo como texto primeiro.
df = pd.read_csv(ENTRADA, sep=",", encoding="cp1252", dtype=str)
log = {"linhas_brutas": len(df)}

def sem_acento(s):
    return unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()

df.columns = [sem_acento(c).lower() for c in df.columns]
df = df.rename(columns={"tipo_pf_pj": "tipo_pessoa", "cpf_cnpj": "documento",
                        "anodoprocesso": "ano_processo", "codigomunicipio": "cod_municipio",
                        "quantidadecomercializada": "quantidade", "unidadedemedida": "unidade",
                        "valorrecolhido": "valor_recolhido", "datacriacao": "data_criacao"})

# 2. Tipos: números com vírgula decimal, inteiros e datas
for c in ["quantidade", "valor_recolhido"]:
    df[c] = pd.to_numeric(df[c].str.replace(",", ".", regex=False), errors="coerce")
df["ano"] = df["ano"].astype(int)
df["mes"] = df["mes"].astype(int)
df["data"] = pd.to_datetime(dict(year=df["ano"], month=df["mes"], day=1)).dt.strftime("%Y-%m-%d")

# 3. Texto: espaços sobrando (a unidade vem como "t  ") e caixa
for c in ["substancia", "unidade", "uf", "municipio", "tipo_pessoa"]:
    df[c] = df[c].str.strip()

# 4. Duplicadas exatas (mesmo processo, valor e data de criação)
dup = int(df.duplicated().sum())
df = df.drop_duplicates()
log["duplicadas_removidas"] = dup

# 5. Agrupar a mesma substância cadastrada com nomes diferentes.
#    Ex.: "FERRO" e "MINÉRIO DE FERRO" são o mesmo bem mineral para a análise.
EQUIV = {"BAUXITA": "ALUMÍNIO", "ESPODUMÊNIO": "LÍTIO", "CALCÁRIO DOLOMÍTICO": "CALCÁRIO",
         "AREIA QUARTZOSA": "AREIA"}
def grupo(s):
    g = re.sub(r"^MINÉRIO DE ", "", s)
    return EQUIV.get(g, g)
df["grupo_substancia"] = df["substancia"].map(grupo)
log["nomes_de_substancia"] = df["substancia"].nunique()
log["grupos_de_substancia"] = df["grupo_substancia"].nunique()
log["linhas_reagrupadas"] = int((df["substancia"] != df["grupo_substancia"]).sum())

# 6. Problemas que ficam marcados, sem apagar a linha (o valor recolhido existe)
df["sem_local"] = df["uf"].isna()
df["quantidade_valida"] = df["quantidade"].fillna(0) > 0
log["sem_uf_municipio"] = int(df["sem_local"].sum())
log["quantidade_zero_ou_vazia"] = int((~df["quantidade_valida"]).sum())

with sqlite3.connect("cfem.db") as con:
    df.to_sql("cfem", con, if_exists="replace", index=False)

log["linhas_finais"] = len(df)
print(log)
