#!/usr/bin/env bash

# Bump versions using semversioner

previous_version=$(semversioner current-version)

semversioner release

new_version=$(semversioner current-version)

echo "Generating CHANGELOG.md file..."
semversioner changelog > CHANGELOG.md

echo "Replace version '$previous_version' to '$new_version' in README.md ..."
sed -i "s/:$previous_version/:$new_version/g" README.md

echo "Replace version '$previous_version' to '$new_version' in pipe.yml ..."
sed -i "s/:$previous_version/:$new_version/g" pipe.yml
