
import os
import boto3
import json


def handler(event,context):
    client = boto3.client("rds")
    client_route = boto3.client("route53")
    region = os.environ['AWS_REGION']
    hosted_zone_id = os.environ['hosted_zone_id']
    eventId = event["detail"]['EventID']
    detail_type = event['detail-type']

    print(f"Event has been fired {eventId}")
    if eventId == "RDS-EVENT-0042" and detail_type == "RDS DB Snapshot Event":
        db_snapshot_id = event['detail']['SourceIdentifier']
        res = client.describe_db_snapshots(DBSnapshotIdentifier=db_snapshot_id)
        res = res['DBSnapshots'][0]
        source_database_id = res['DBInstanceIdentifier']

        print(f"restoring from source database {source_database_id}")
        blue_database = client.describe_db_instances(DBInstanceIdentifier=source_database_id)["DBInstances"][0]
        vpc_security_groups_ids = [item['VpcSecurityGroupId'] for  item in blue_database['VpcSecurityGroups']]
        db_subnet_group_names = blue_database['DBSubnetGroup']['DBSubnetGroupName']

        
        # Copy Snapshot to Green database
        restore_response = client.restore_db_instance_from_db_snapshot(
            DBSnapshotIdentifier=db_snapshot_id,
            DBInstanceIdentifier="greendb",
            VpcSecurityGroupIds=vpc_security_groups_ids,
            DBSubnetGroupName=db_subnet_group_names
        )
    elif eventId == "RDS-EVENT-0043" and detail_type == "RDS DB Snapshot Event":

        print("Creating Hosted Zone Record for routing db host traffic")
        source_database_id = event['detail']['SourceIdentifier']
        restored_database = client.describe_db_instances(DBInstanceIdentifier=source_database_id)["DBInstances"][0]
        print(restored_database['Endpoint'])
        
        response = client_route.change_resource_record_sets(
            HostedZoneId=hosted_zone_id,
            ChangeBatch={
                'Comment': 'string',
                'Changes': [
                    {
                        'Action': 'UPSERT',
                        'ResourceRecordSet': {
                            'Name': 'green_database.app.database',
                            'Type': 'CNAME',
                            'TTL': 60,
                            'ResourceRecords': [
                                {
                                    'Value': restored_database['Endpoint']
                                },
                            ]
                        }
                    },
                ]
            }
        )
    
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "Event ": eventId
        })
    }