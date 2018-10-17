#!/usr/bin/env bash
#
# Merge back to the develop branch.
#   - On master, we merge back to develop.
#   - On release/<foo>, we merge back to develop/<foo>
#
# Required globals:
#   BITBUCKET_BRANCH: The current git branch.
#


set -e

# Determine what branch we are merging back to...
if [[ "${BITBUCKET_BRANCH}" =~ "release-" ]]; then
    develop_branch="develop-$(echo "${BITBUCKET_BRANCH}" | cut -d '-' -f2)"
elif [[ "${BITBUCKET_BRANCH}" == "master" ]]; then
    develop_branch="develop"
else
    echo "ERROR: Can only merge back to develop[-*] branches from master or a release-* branch."
    exit 1
fi


# Update the development branch
GIT_SSH_COMMAND="ssh -i ~/.ssh/id_rsa -F /dev/null" git fetch origin "${develop_branch}:${develop_branch}"
git checkout "${develop_branch}"
git merge "${BITBUCKET_BRANCH}"
GIT_SSH_COMMAND="ssh -i ~/.ssh/id_rsa -F /dev/null" git push origin "${develop_branch}"
exit 0
