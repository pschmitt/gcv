#!/usr/bin/env sh
cd ..
processing-java --sketch=github --output=output --export --force
./output/github $1 $2 
cd -
