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
    if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
        echo "\$AWS_ACCESS_KEY_ID environment variable not set"
        exit 1
    fi

    if [[ -z "$AWS_SECRET_ACCESS_KEY" ]]; then
        echo "\$AWS_SECRET_ACCESS_KEY environment variable not set"
        exit 1
    fi

    if [[ -z "$AWS_DEFAULT_REGION" ]]; then
        echo "\$AWS_DEFAULT_REGION environment variable not set"
        exit 1
    fi
}

prepare(){
    export TF_VAR_aws_access_key="$AWS_ACCESS_KEY_ID"
    export TF_VAR_aws_secret_key="$AWS_SECRET_ACCESS_KEY"
}

updateAmi(){
    export TF_VAR_ami_id=`aws ec2 create-image --instance-id $INSTANCE --name $3 --output text`
    aws ec2 wait image-available --image-ids "$TF_VAR_ami_id"
}

cleanUp(){
    aws ec2 deregister-image --image-id $LAST_AMI_ID
}