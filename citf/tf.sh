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

    INSTANCE="${ci_instance_id%\"}"
    INSTANCE="${INSTANCE#\"}"
    LAST_AMI_ID="${ci_last_ami_id%\"}"
    LAST_AMI_ID="${LAST_AMI_ID#\"}"
    TARGET_HOST="${ci_instance_ip%\"}"
    TARGET_HOST="${TARGET_HOST#\"}"
    TARGET_HOST="${REMOTE_USER}@${TARGET_HOST}"
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