#!/bin/bash
STACK_NAME="$1"
ENV_FILE="${2:-.env}"

if [[ ! "$STACK_NAME" ]] ; then
    echo "Usage: $0 STACK [ .env ]"
    exit 1
fi

if [[ ! -e "$ENV_FILE" ]] ; then
    echo "Env file $ENV_FILE does not exist"
    exit 1
fi

docker stack deploy --compose-file=<( set -a; source $ENV_FILE ; test -e .versions && source .versions; set +a; docker-compose -f docker-compose.yml -f docker-compose-infra.yml config 2>/dev/null |tee .docker-compose-latest.yml ) $STACK_NAME

