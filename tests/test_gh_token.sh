#!/bin/bash

curl -fL \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: token $ACCESS_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    'https://api.github.com/repos/UrbanOS-Public/ubi-hive/actions/artifacts?name=hadoop-artifact'
