"""
Quick sanity check that the target PostgreSQL 17 cluster is reachable
and reports the expected version, useful right after cutover.

    $ python verify_connection.py
"""

import psycopg2

conf = {
    "host": "pg-cluster.example.com",
    "port": "6432",
    "user": "postgres",
    "password": "changeme",
    "dbname": "app_db",
}

conn = psycopg2.connect(**conf)
cursor = conn.cursor()

cursor.execute("SELECT version();")
print(cursor.fetchone())

cursor.execute("SELECT inet_server_addr(), inet_server_port();")
print(cursor.fetchone())

cursor.close()
conn.close()
