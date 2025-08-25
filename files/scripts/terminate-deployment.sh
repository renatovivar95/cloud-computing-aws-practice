#!/bin/bash

source config.sh

# Step 1: delete auto scaling group.
aws autoscaling delete-auto-scaling-group \
	--auto-scaling-group-name "$ASG_NAME" \
	--force-delete

# Step 2: delete launch configuration.
aws autoscaling delete-launch-configuration \
	--launch-configuration-name "$LAUNCH_CONFIG_NAME"

# Step 3: delete load balancer.
aws elb delete-load-balancer \
	--load-balancer-name "$LB_NAME"
