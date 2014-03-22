#!/usr/bin/env sh

TOKEN_FILE=token
SKETCH=../github
OUTPUT=output
REPO=$(git remote show origin | grep -m1 -o "https://.*" | sed 's|https://github.com/\(.*\)|\1|g')

processing-java --sketch=$SKETCH --output=$OUTPUT --export --force

[[ -n $1 ]] && REPO=$1
[[ -r $TOKEN_FILE ]] && TOKEN=$(cat $TOKEN_FILE) || TOKEN=$2

./$OUTPUT/github $REPO $TOKEN

