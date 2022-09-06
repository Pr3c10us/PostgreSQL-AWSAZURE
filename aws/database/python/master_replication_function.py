
from doctest import master
import os
import boto3
import json
import psycopg2


def handler(event,context):
    client = boto3.client("rds")
    master_host = os.environ['master_host']
    replicate_host = os.environ['replicate_host']
    database = "mydb"
    username = "foo"
    password = "foobarbaz"

    master_conn = psycopg2.connect(
        host=master_host,
        database=database,
        user=username,
        password=password
    )

    replicate_conn = psycopg2.connect(
        host=replicate_host,
        database=database,
        user=username,
        password=password
    )
    try:
        master_cur = master_conn.cursor()
        master_cur.execute('SELECT version()')
        db_version = master_cur.fetchone()
        print(db_version)

    except Exception as e:
        print(e)
   
    master_conn.close()
    replicate_conn.close()
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
    }