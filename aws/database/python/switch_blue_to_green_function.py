
import os
import boto3
import json


def handler(event,context):
    
    client = boto3.client("route53")
    hosted_zone_id = os.environ['hosted_zone_id']
    hosted_zone_id = "Z00991903URFUHILOPE7M"
    response = client.list_resource_record_sets(
        HostedZoneId=hosted_zone_id,
    )
    cname_databases = list(filter(lambda item:item['Type']=="CNAME",response['ResourceRecordSets']))
    green_database = list(filter(lambda item:item['Name']=="green_database.app.database.",cname_databases))[0]
    blue_database = list(filter(lambda item:item['Name']=="blue_database.app.database.",cname_databases))[0]

    print("Switching green record to blue record   ")
    response = client.change_resource_record_sets(
        HostedZoneId=hosted_zone_id,
        ChangeBatch={
            'Comment': 'string',
            'Changes': [
                {
                    'Action': 'UPSERT',
                    'ResourceRecordSet': {
                        'Name': 'green_database.app.database',
                        'Type': 'CNAME',
                        'TTL': 123,
                        'ResourceRecords': [
                            {
                                'Value': blue_database['ResourceRecords'][0]['Value']
                            },
                        ]
                    }
                },
            ]
        }
    )
    print("Switching blue record to green record ")
    response = client.change_resource_record_sets(
        HostedZoneId=hosted_zone_id,
        ChangeBatch={
            'Comment': 'string',
            'Changes': [
                {
                    'Action': 'UPSERT',
                    'ResourceRecordSet': {
                        'Name': 'blue_database.app.database',
                        'Type': 'CNAME',
                        'TTL': 123,
                        'ResourceRecords': [
                            {
                                'Value': green_database['ResourceRecords'][0]['Value']
                            },
                        ]
                    }
                },
            ]
        }
    )
    
    response = client.modify_db_instance(
        DBInstanceIdentifier='bluedb',
        NewDBInstanceIdentifier="bluedbbackup"
    )

    # change database identifier
    response = client.modify_db_instance(
        DBInstanceIdentifier='greendb',
        NewDBInstanceIdentifier="bluedb"
    )

    response = client.delete_db_instance(
        DBInstanceIdentifier='bluedb',
    )

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
    }