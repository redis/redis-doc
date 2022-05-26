#!/bin/bash
# Prepares the Netlify preview
: ${REDIS_STACK_REPOSITORY:="github.com/redis-stack/redis-stack-website"}
if [[ -n $PRIVATE_ACCESS_TOKEN ]]; then
    REDIS_STACK_REPOSITORY="$PRIVATE_ACCESS_TOKEN@$REDIS_STACK_REPOSITORY"
fi
repo_dir=$(pwd)

rm -rf website
git clone --recurse-submodules https://$REDIS_STACK_REPOSITORY website
cd website
REPO_DIR=$repo_dir REPOSITORY_URL=$REPOSITORY_URL PREVIEW_MODE=1 make deps netlify
