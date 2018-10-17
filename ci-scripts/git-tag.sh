#!/bin/bash
#
# Tag the current branch with the next
# version number, push the tag back to the remote.

set -e

# Tag and push
tag=$(cat next.version)
if [[ "${BITBUCKET_BRANCH}" =~ "qa-" ]]; then
    tag="${tag}-qa-${BITBUCKET_BUILD_NUMBER}"
fi

git tag -a -m "Tagging for release ${tag}" "${tag}"
GIT_SSH_COMMAND="ssh -i ~/.ssh/id_rsa -F /dev/null" git push origin ${tag}

