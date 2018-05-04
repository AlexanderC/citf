#!/usr/bin/env bash

main(){
    check
    if [[ "$(type -t "$2")" = function ]]; then
        $2 $@
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
    ami_id=`aws ec2 create-image --instance-id $INSTANCE --name $3 --output text`
    aws ec2 wait image-available --image-ids "$ami_id"
    echo \"$ami_id\"
}

cleanUp(){
    aws ec2 deregister-image --image-id $LAST_AMI_ID
    aws ec2 terminate-instances --instance-ids $OLD_INSTANCES
}

help(){
echo -e "
citf remote <SUBCOMMAND> [args...]
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