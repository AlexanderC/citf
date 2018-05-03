#!/usr/bin/env bash

main(){
    check
    if [[ "$(type -t "$2")" = function ]]; then
        $2 $@
    else
        show_help
    fi
}

check(){
    if [[ -z "$TF_WORKSPACE" ]]; then
        echo "\$TF_WORKSPACE environment variable not set"
        exit 1
    fi

    if [[ -z "$TERRAFORM_FOLDER" ]]; then
        echo "\$TERRAFORM_FOLDER environment variable not set"
        exit 1
    fi

    if [[ -z "$S3_BUCKET_TF_STATE" ]]; then
        echo "\$S3_BUCKET_TF_STATE environment variable not set"
        exit 1
    fi

    if [[ -z "$TF_VAR_aws_access_key" ]]; then
        echo "\$TF_VAR_aws_access_key environment variable not set"
        exit 1
    fi

    if [[ -z "$TF_VAR_aws_secret_key" ]]; then
        echo "\$TF_VAR_aws_secret_key environment variable not set"
        exit 1
    fi

    if [[ -z "$REMOTE_USER" ]]; then
        echo "\$REMOTE_USER environment variable not set"
        exit 1
    fi
}

prepare(){

    cd $TERRAFORM_FOLDER
    aws s3 cp s3://$S3_BUCKET_TF_STATE/terraform.tfstate.d/$TF_WORKSPACE/terraform.tfstate terraform.tfstate.d/$TF_WORKSPACE/terraform.tfstate
    aws s3 cp s3://$S3_BUCKET_TF_STATE/terraform.tfstate.d/$TF_WORKSPACE/terraform.tfstate.backup terraform.tfstate.d/$TF_WORKSPACE/terraform.tfstate.backup

    terraform init -input=false
    export $(tf-output outputs -p '')

    export ASG_NAME="${autoscaling_g_name%\"}"
    ASG_NAME="${ASG_NAME#\"}"

    export INSTANCE="${ci_instance_id%\"}"
    INSTANCE="${INSTANCE#\"}"

    export LAST_AMI_ID="${ci_last_ami_id%\"}"
    LAST_AMI_ID="${LAST_AMI_ID#\"}"

    export TARGET_HOST="${ci_instance_ip%\"}"
    TARGET_HOST="${TARGET_HOST#\"}"
    TARGET_HOST="${REMOTE_USER}@${TARGET_HOST}"

    export OLD_INSTANCES=`aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME | jq -r '.AutoScalingGroups[].Instances[].InstanceId'`
}

update(){
    export TF_VAR_desired_capacity=4
    export TF_VAR_min_size=4
    terraform plan -out=tfplan -input=false
    terraform apply -input=false tfplan
    export TF_VAR_desired_capacity=2
    export TF_VAR_min_size=2
    terraform plan -out=tfplan -input=false
    terraform apply -input=false tfplan
}

saveState(){
    aws s3 cp terraform.tfstate.d/$TF_WORKSPACE/terraform.tfstate s3://$S3_BUCKET_TF_STATE/terraform.tfstate.d/$TF_WORKSPACE/terraform.tfstate
    aws s3 cp terraform.tfstate.d/$TF_WORKSPACE/terraform.tfstate.backup s3://$S3_BUCKET_TF_STATE/terraform.tfstate.d/$TF_WORKSPACE/terraform.tfstate.backup
}

show_help(){
echo -e "
citf tf <SUBCOMMAND> [args...]
docker-compose related commands
SUBCOMMANDS:
rdo <command>
    Run a command on remote server.
    Example: citf remote rdo 'bash update-server.sh'
    Will run ssh \$TARGET_HOST 'cd \$TARGET_PATH; bash update-server.sh'
copy <source> <destination>
    Perform a 'scp' from 'source' to remote 'destination'
    Example: citf remote copy ../bin/update-server.sh /update-server.sh
    Will run scp ../bin/update-server.sh \$TARGET_HOST:\$TARGET_PATH/update-server.sh
"
}