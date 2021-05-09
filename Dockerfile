FROM amazon/aws-cli

RUN yum install -y jq

RUN yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm && \
    amazon-ssm-agent -version

COPY ssm-auth.sh .
COPY startup.sh .

ENTRYPOINT ./startup.sh
