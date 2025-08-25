#!/bin/bash

# Set working directory (optional)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Example PATH config (modify if needed)
export PATH="$HOME/aws-cli-bin:$PATH"

# AWS credentials — insert your current session credentials here
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_ACCESS_KEY"
export AWS_SESSION_TOKEN="YOUR_SESSION_TOKEN"

# Optional environment settings
export AWS_DEFAULT_REGION="us-east-1"
export AWS_ACCOUNT_ID="123456789012"
export AWS_EC2_SSH_KEYPAR_PATH="~/.ssh/my-key.pem"
export AWS_SECURITY_GROUP="sg-xxxxxxxx"
export AWS_KEYPAIR_NAME="my-keypair"

# Resource names
export LB_NAME="CNV-LoadBalancer100"
export LAUNCH_CONFIG_NAME="CNV-LaunchConfiguration100"
export POLICY_INCREASE_NAME="IncreaseGroupSize100"
export ASG_NAME="CNV-AutoScalingGroup100"
export POLICY_DECREASE_NAME="DecreaseGroupSize100"
export ALARM_HIGH_NAME="HighCPUUtilizationAlarm100"
export ALARM_LOW_NAME="LowCPUUtilizationAlarm100"
export AWS_REGION="us-east-1"
export AWS_AVAILABILITY_ZONE="us-east-1a"
export IMAGE_NAME="CNV-Image100"
