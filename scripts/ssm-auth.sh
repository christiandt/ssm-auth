#!/usr/bin/env bash

# This script will create new ssm activation IDs for every new startup, and remove the old keys. This means that
# scaling will remove the keys of all nodes except for the latest one. Consider storing the key file in secretsmanager
# or in S3 when scaling. If doing so, the activation limit needs to be taken into account.

INSTANCENAME=${INSTANCENAME:-ssm-container}
CREDFILE=ssm_keys.txt
AWS_REGION=${AWS_REGION:-eu-west-1}
SSMROLE=${SSMROLE:-SSMRole}

# Created credentials will only be stored in $CREDFILE on the host in the current implementation
createCredentials () {
    echo "Generating new SSM credentials ..."
    aws ssm create-activation \
            --default-instance-name ${INSTANCENAME} \
            --description ${INSTANCENAME} \
            --iam-role ${SSMROLE} \
            --registration-limit 1 \
            --region ${AWS_REGION} \
            --tags Key=Name,Value=${INSTANCENAME} \
            > ${CREDFILE}
}

# All disconnected instances will be removed, as we do rolling update, there will constantly be at least one more
# connected instance.
removeDisconnectedInstances () {
    echo "Removing disconnected instances ..."
    for instance_id in $(aws ssm describe-instance-information \
        --filter 'Key=PingStatus,Values=ConnectionLost' \
        --query 'InstanceInformationList[*].InstanceId' \
        --output text); do
        aws ssm deregister-managed-instance --instance-id ${instance_id}
    done
}

if [[ $1 = "disconnect" ]]; then
    ACTIVATION_ID=$(cat ${CREDFILE} | jq .ActivationId -r)
    INSTANCE_ID=$(cat /var/lib/amazon/ssm/registration | jq .ManagedInstanceID -r)

    echo "Deleting existing ssm credentials ..."
    aws ssm delete-activation --activation-id ${ACTIVATION_ID}

    echo "Removing instances with ID ${INSTANCE_ID}..."
    aws ssm deregister-managed-instance --instance-id ${INSTANCE_ID} && echo "Deregistered"

elif [[ $1 = "connect" ]]; then

    # Create credentials if not existing, remove old and create new if existing (as we cannot get the old values from aws)
    if [[ $(aws ssm describe-activations \
        --filter FilterKey=DefaultInstanceName,FilterValues=${INSTANCENAME} \
        --query 'ActivationList[*]' | jq '. | length') = 0 ]]; then
        createCredentials
    else
        echo "Deleting existing ssm credentials ..."
        for aid in $(aws ssm describe-activations \
            --filter FilterKey=DefaultInstanceName,FilterValues=${INSTANCENAME} \
            --query 'ActivationList[*].ActivationId' \
            --output text); do
            aws ssm delete-activation --activation-id ${aid}
        done
        createCredentials
    fi

    removeDisconnectedInstances

    ACTIVATION_ID=$(cat ${CREDFILE} | jq .ActivationId -r)
    ACTIVATION_CODE=$(cat ${CREDFILE} | jq .ActivationCode -r)
    amazon-ssm-agent -register -code ${ACTIVATION_CODE} -id ${ACTIVATION_ID} -region ${AWS_REGION} -y

    # Add ssm-user to sudo group
    echo "ssm-user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers
else
    echo Invalid option
fi
