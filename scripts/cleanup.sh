#!/usr/bin/env bash

AWS_REGION=${AWS_REGION:-eu-west-1}
INSTANCENAME=${INSTANCENAME:-ssm-container}
CREDFILE=ssm_keys.txt


echo "Removing instances with tag-name ${INSTANCENAME}..."
for instance_id in $(aws ssm describe-instance-information \
    --filter Key=tag:Name,Values=${INSTANCENAME} \
    --query 'InstanceInformationList[*].InstanceId' \
    --output text); do
    aws ssm deregister-managed-instance --instance-id ${instance_id}
done

echo "Deleting existing ssm credentials ..."
for aid in $(aws ssm describe-activations \
    --filter FilterKey=DefaultInstanceName,FilterValues=${INSTANCENAME} \
    --query 'ActivationList[*].ActivationId' \
    --output text); do
    aws ssm delete-activation --activation-id ${aid}
done
