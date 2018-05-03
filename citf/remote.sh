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
    if [[ -z "$TARGET_HOST" ]]; then
        echo "\$TARGET_HOST environment variable not set"
        exit 1
    fi
}


rdo(){
    ssh $TARGET_HOST "cd $TARGET_PATH; $3"
}

copy(){
    if [[ -z "$3" ]]; then
        echo "Source is not set. Please check documentation"
        exit 1
    fi
    if [[ -z "$4" ]]; then
        echo "Destination is not set. Please check documentation"
        exit 1
    fi
    scp $3 "${TARGET_HOST}:${TARGET_PATH}${4}"
}

show_help(){
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