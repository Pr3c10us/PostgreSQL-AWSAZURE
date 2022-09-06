
import os
import boto3
import json


def handler(event,context):
    snapshot_name = 'green-rds-snaphot'
    master_database_id = event["master_database_id"]
    client = boto3.client("rds")

    # Creating Snapshot from source
    client.create_db_snapshot(
        DBSnapshotIdentifier=snapshot_name,
        DBInstanceIdentifier=master_database_id,
    )
    
    
    
 
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
    }