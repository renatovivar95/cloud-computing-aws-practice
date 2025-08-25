#!/bin/bash

source config.sh

# Create Load Balancer and configure health check
aws elb create-load-balancer \
	--load-balancer-name $LB_NAME \
	--listeners "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=8000" \
	--availability-zones $AWS_AVAILABILITY_ZONE

aws elb configure-health-check \
  --load-balancer-name $LB_NAME \
  --health-check "Target=HTTP:8000/,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=5"

# Create Launch Configuration
aws autoscaling create-launch-configuration \
	--launch-configuration-name $LAUNCH_CONFIG_NAME \
	--image-id $(cat image.id) \
	--instance-type t2.micro \
	--security-groups $AWS_SECURITY_GROUP \
	--key-name $AWS_KEYPAIR_NAME \
	--instance-monitoring Enabled=true

# Create Auto Scaling Group
aws autoscaling create-auto-scaling-group \
	--auto-scaling-group-name $ASG_NAME \
	--launch-configuration-name $LAUNCH_CONFIG_NAME \
	--load-balancer-names $LB_NAME \
	--availability-zones $AWS_AVAILABILITY_ZONE \
	--health-check-type ELB \
	--health-check-grace-period 60 \
	--min-size 1 \
	--max-size 3 \
	--desired-capacity 1

# Create Scaling Policies and store their ARNs
increase_policy_arn=$(aws autoscaling put-scaling-policy \
	--auto-scaling-group-name $ASG_NAME \
	--policy-name $POLICY_INCREASE_NAME \
	--scaling-adjustment 1 \
	--adjustment-type ChangeInCapacity \
	--cooldown 300 \
	--query PolicyARN --output text)

decrease_policy_arn=$(aws autoscaling put-scaling-policy \
	--auto-scaling-group-name $ASG_NAME \
	--policy-name $POLICY_DECREASE_NAME \
	--scaling-adjustment -1 \
	--adjustment-type ChangeInCapacity \
	--cooldown 300 \
	--query PolicyARN --output text)

# CloudWatch Alarm for High CPU utilization
aws cloudwatch put-metric-alarm \
	--alarm-name $ALARM_HIGH_NAME \
	--alarm-description "Scale out when CPU > 50%" \
	--metric-name CPUUtilization \
	--namespace AWS/EC2 \
	--statistic Average \
	--period 60 \
	--threshold 50 \
	--comparison-operator GreaterThanThreshold \
	--evaluation-periods 1 \
	--alarm-actions $increase_policy_arn \
	--dimensions "Name=AutoScalingGroupName,Value=$ASG_NAME"

# CloudWatch Alarm for Low CPU utilization
aws cloudwatch put-metric-alarm \
	--alarm-name $ALARM_LOW_NAME \
	--alarm-description "Scale in when CPU < 25%" \
	--metric-name CPUUtilization \
	--namespace AWS/EC2 \
	--statistic Average \
	--period 60 \
	--threshold 25 \
	--comparison-operator LessThanThreshold \
	--evaluation-periods 1 \
	--alarm-actions $decrease_policy_arn \
	--dimensions "Name=AutoScalingGroupName,Value=$ASG_NAME"
