FROM amazon/aws-cli

RUN yum install -y jq

RUN yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm && \
    amazon-ssm-agent -version

#RUN amazon-linux-extras enable ecs && yum clean metadata && yum install -y ecs-init

COPY .aws /root/.aws
COPY seelog.xml /etc/amazon/ssm/seelog.xml
COPY scripts/*.sh ./

ENTRYPOINT ["./startup.sh"]
