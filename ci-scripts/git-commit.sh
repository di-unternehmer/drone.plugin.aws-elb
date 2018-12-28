#!/bin/bash

# Commit back to the repository
# version number, push the tag back to the remote.

set -e

# Tag and push
tag=$(semversioner current-version)
if [[ "${BITBUCKET_BRANCH}" =~ "qa-" ]]; then
    tag="${tag}-qa-${BITBUCKET_BUILD_NUMBER}"
fi

git add .
git commit -m "Update files for new version '${tag}' [skip ci]"
GIT_SSH_COMMAND="ssh -i ~/.ssh/id_rsa -F /dev/null" git push origin ${BITBUCKET_BRANCH}
