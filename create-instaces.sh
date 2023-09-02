#!/bin/bash
N=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "web")
INSTANCE_TYPE=""
ami_id=ami-03265a0778a880afb
sg_id=sg-05427928f3dcf34cd
hosted_zone_id=Z10109841U3NZMA5ICBEK
domain_name=awsdevopslearning.online
for i in ${N[@]}
do
    if [[ $i == "mongodb" || $i == "mysql" ]]
    then 
    INSTANCE_TYPE=t3.micro
    else
    INSTANCE_TYPE=t2.micro
    fi
    instance_ids=$(aws ec2 describe-instances --filters Name=tag:Name,Values="'$i'" | jq -r '.Reservations[].Instances[].InstanceId')
    for instance_id in $instance_ids
    do
        running=$(aws ec2 describe-instances --instance-ids $instance_id | jq -r '.Reservations[].Instances[].State.Name')
            if [ "$running" == "running" ]
            then 
                echo "The EC2 instance $instance_id is already running. Not launching a new instance."
                exit 1
            fi
    done
    echo "Creating $i instance"
    j=$(aws ec2 run-instances --image-id $ami_id --instance-type $INSTANCE_TYPE --security-group-ids $sg_id --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" | jq -r '.Instances[0].PrivateIpAddress')
    echo "Respective private for the $i instance is $j" 
    aws route53 change-resource-record-sets --hosted-zone-id $hosted_zone_id --change-batch '
    {
        "Changes": [
            {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "'$i.$domain_name'",
                    "Type": "A",
                    "TTL": 1,
                    "ResourceRecords": [{ "Value": "'$j'"}]
                }
            }
        ]
    }'
done