## Must fill correct requirement ENV
REGION=ap-southeast-1
STACK_NAME=<Cluster-Name>
COMPANY=<COMPANY-NAME>
DEPLOYABLE_SERVICES=<Service-Name>
REPOSITORY=<REPOID>.dkr.ecr.ap-southeast-1.amazonaws.com
DOMAIN=<APPS-DOMAIN>
HOSTPORT=31020
## End of requirement ENV

LISTENER-ARN=$$(sed -n '1p' LISTENER_ARN.txt)
LISTENER-ARN-HTTPS=$$(sed -n '1p' LISTENER_ARN_HTTPS.txt)
SERVICE_NAME=$(DEPLOYABLE_SERVICES)
VERSION=$$(cat VERSION)
TARGET-GROUP-ARN =$$(sed -n '1p' TARGET_GROUP_ARN.txt)
RESULTS_ARRAY=($RESULTS)
CLUSTER_NAME=$$(sed -n '1p' results.txt)
ALB_ARN=$$(sed -n '2p' results.txt)
ECS_ROLE=$$(sed -n '3p' results.txt)
URL=$$(sed -n '4p' results.txt)
VPCID=$$(sed -n '5p' results.txt)


# Define Stack Cloudformation
RESULTS:
	aws cloudformation describe-stacks \
	--stack-name $(STACK_NAME) \
	--region $(REGION) \
	--query "[Stacks[0].Outputs[?OutputKey==\`ClusterName\`].OutputValue,Stacks[0].Outputs[?OutputKey==\`ALBArn\`].OutputValue,Stacks[0].Outputs[?OutputKey==\`ECSRole\`].OutputValue,Stacks[0].Outputs[?OutputKey==\`Url\`].OutputValue,Stacks[0].Outputs[?OutputKey==\`VPCId\`].OutputValue]" \
	--output text > results.txt

# Login to ECR for Push Image
ECS_LOGIN:
	$$(aws ecr get-login --no-include-email --region $(REGION))

# Create ECR Repository container image 
REPO:
	aws ecr create-repository --region $(REGION) --repository-name $(SERVICE_NAME) --query "repository.repositoryUri" --output text

# Build Image on Local REPO based dockerfile
build_image:
	docker build -t $(SERVICE_NAME) .

# Tagging image based on build image
image_tag:
	docker tag $(SERVICE_NAME) $(REPOSITORY)/$(SERVICE_NAME):latest
	docker tag $(SERVICE_NAME) $(REPOSITORY)/$(SERVICE_NAME):$(VERSION)

# Push image to ECR Repository
image_push:
	docker push $(REPOSITORY)/$(SERVICE_NAME):latest
	docker push $(REPOSITORY)/$(SERVICE_NAME):$(VERSION)

# Create Task definition on ECS
TASK_DEFINITION_ARN:
	aws ecs register-task-definition \
	--region $(REGION) \
	--family $(SERVICE_NAME) \
	--container-definitions "[{\"name\": \"$(SERVICE_NAME)\",\"image\": \"$(REPOSITORY)/$(SERVICE_NAME):latest\",\"cpu\": 256,\"memory\": 1024,\"portMappings\": [{\"containerPort\": 80,\"hostPort\": $(HOSTPORT)}],\"logConfiguration\": {\"logDriver\": \"awslogs\",\"options\": {\"awslogs-group\": \"ECSLogGroup-cluster\",\"awslogs-region\": \"ap-southeast-1\",\"awslogs-stream-prefix\": \"app-INFO\"}},\"essential\": true}]" \
	--query "taskDefinition.taskDefinitionArn" \
	--output text

# Create Service on ECS based by task definition
SERVICE_DEFINITION:
	aws ecs create-service \
	--region $(REGION) \
	--cluster $(CLUSTER_NAME) \
	--service-name $(SERVICE_NAME) \
	--task-definition $(SERVICE_NAME) \
        --deployment-configuration maximumPercent=150,minimumHealthyPercent=50 \
	--load-balancers targetGroupArn=$(TARGET-GROUP-ARN),containerName=$(SERVICE_NAME),containerPort=80 \
	--desired-count 4

# Create Target Group for Service
TARGET_GROUP:
	aws elbv2 create-target-group \
	--region $(REGION) \
	--name $(SERVICE_NAME) \
	--vpc-id $(VPCID) \
	--port $(HOSTPORT) \
	--protocol HTTP \
	--health-check-protocol HTTP \
	--health-check-path / \
	--health-check-interval-seconds 6 \
	--health-check-timeout-seconds 5 \
	--healthy-threshold-count 2 \
	--unhealthy-threshold-count 2 \
	--query "TargetGroups[0].TargetGroupArn" \
	--output text > TARGET_GROUP_ARN.txt

# Create Listener on ALB (path based with port)
LISTENER_ARN:
	aws elbv2 create-listener \
	--region $(REGION) \
	--load-balancer-arn $(ALB_ARN) \
	--port 80 \
	--protocol HTTP \
	--query "Listeners[0].ListenerArn" \
	--default-actions Type=forward,TargetGroupArn=$(TARGET-GROUP-ARN) \
	--output text > LISTENER_ARN.txt

# Add Host Based Rule to Listener on ALB
RULE_ADD:
	aws elbv2 create-rule \
	--region $(REGION) \
	--listener-arn $(LISTENER-ARN) \
	--priority 5 \
	--conditions Field=host-header,Values='$(DOMAIN)' \
	--actions Type=forward,TargetGroupArn=$(TARGET-GROUP-ARN)

LISTENER_ARN_HTTPS:
	aws elbv2 create-listener \
	--load-balancer-arn $(ALB_ARN) \
	--protocol HTTPS \
	--port 443 \
	--certificates <SSL-CERTIFICATE> \
	--ssl-policy ELBSecurityPolicy-2016-08 \
	--query "Listeners[0].ListenerArn" \
	--default-actions Type=forward,TargetGroupArn=$(TARGET-GROUP-ARN) \
	--output text > LISTENER_ARN_HTTPS.txt

RULE_ADD_HTTPS:
	aws elbv2 create-rule \
	--region $(REGION) \
	--listener-arn $(LISTENER-ARN-HTTPS) \
	--priority 5 \
	--conditions Field=host-header,Values='$(DOMAIN)' \
	--actions Type=forward,TargetGroupArn=$(TARGET-GROUP-ARN)

# update servie no down time
aws_update_service_no_down:
	aws ecs update-service \
	--cluster $(CLUSTER_NAME) \
	--service $(SERVICE_NAME) \
        --deployment-configuration maximumPercent=150,minimumHealthyPercent=25 \
	--force-new-deployment \
        --desired-count 4

#update servici with down time
aws_update_service:
	aws ecs update-service \
	--cluster $(CLUSTER_NAME) \
	--service $(SERVICE_NAME) \
	--deployment-configuration maximumPercent=100,minimumHealthyPercent=0 \
	--force-new-deployment \
	--desired-count 1

aws_ecr_login:
	@$(ECS_LOGIN)

aws_task_check:
	@$(ECS_LOGIN) TASK_DEFINITION_ARN

aws_create_repo: REPO

aws_build_tag: build_image image_tag

aws_build_tag_push: ECS_LOGIN build_image image_tag image_push

aws_container_first_deploy: REPO aws_create_repo aws_build_tag_push RESULTS TASK_DEFINITION_ARN TARGET_GROUP LISTENER_ARN LISTENER_ARN_HTTPS SERVICE_DEFINITION RULE_ADD RULE_ADD_HTTPS
