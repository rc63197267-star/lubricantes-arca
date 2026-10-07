import base64
import json
import os
import sqlite3
import subprocess

STATE = os.path.expanduser("~/.config/Code/User/globalStorage/state.vscdb")
ENV = "/home/adan/proyectoarca/ml/.runtime/postgres.env"
EXT_KEY = "cweijan.vscode-database-client2"
CONN_KEY = "1791045000000"

vals = {}
with open(ENV, encoding="utf-8") as f:
    for line in f:
        if "=" in line and not line.lstrip().startswith("#"):
            k, v = line.rstrip("\n").split("=", 1)
            vals[k] = v

password = vals["POSTGRES_PASSWORD"]
key_hex = b"BDFHJLNPpnljhfdb".hex()
iv_hex = b"qeO9xrUlSC7bK2s3".hex()
enc = subprocess.run(
    ["openssl", "enc", "-aes-128-cbc", "-K", key_hex, "-iv", iv_hex, "-base64", "-A"],
    input=password.encode(),
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    check=True,
).stdout.decode().strip()

conn = sqlite3.connect(STATE, timeout=10)
row = conn.execute("SELECT value FROM ItemTable WHERE key=?", (EXT_KEY,)).fetchone()
if not row:
    raise SystemExit("No se encontro la configuracion de Database Client")

data = json.loads(row[0])
connections = data.setdefault("database.connections", {})

connections[CONN_KEY] = {
    "host": "127.0.0.1",
    "port": 5432,
    "user": "arca",
    "password": "dbclient_a$" + enc,
    "dbType": "PostgreSQL",
    "database": "lubricantes_arca",
    "name": "Lubricantes Arca PostgreSQL",
    "advance": {
        "idleConfig": {"enable": True},
        "hideSystemSchema": True,
        "groupingTables": False,
        "loadMetaDataWhenExpandTreeView": True,
    },
    "treeFeatures": [],
    "usingSSH": False,
    "useSocksProxy": False,
    "useHTTPProxy": False,
    "global": True,
    "savePassword": "Forever",
    "readonly": False,
    "sort": 13,
    "useSSL": False,
    "fs": {"encoding": "utf8", "showHidden": True},
    "key": CONN_KEY,
    "connectionKey": "database.connections",
}

conn.execute(
    "UPDATE ItemTable SET value=? WHERE key=?",
    (json.dumps(data, separators=(",", ":"), ensure_ascii=False), EXT_KEY),
)
conn.commit()
conn.close()

print("OK: Lubricantes Arca PostgreSQL -> 127.0.0.1:5432/lubricantes_arca")
