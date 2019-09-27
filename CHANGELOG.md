# Changelog
Note: version releases in the 0.x.y range may introduce breaking changes.

## 0.5.2

- patch: Internal maintenance: Automate test infrastructure.

## 0.5.1

- patch: Internal release.

## 0.5.0

- minor: Changed the default value for the DESCRIPTION to be the pipeline URL.

## 0.4.1

- patch: Internal maintenance: Fix versioning

## 0.4.0

- minor: New DESCRIPTION parameter was introduced
- patch: Fixed testing dependencies

## 0.3.2

- patch: Fix incorrect S3 key being reported during deploy

## 0.3.1

- patch: Refactor pipe code to use pipes bash toolkit.

## 0.3.0

- minor: The pipe will now use the APPLICATION_NAME variable to create a subfolder in the S3 bucket. This will allow better artifacts organisation when reusing the same bucket for many applications.

## 0.2.9

- patch: Fixed preserve the extension of the application source bundle

## 0.2.8

- patch: Pipe now correctly handles failed environment updates

## 0.2.7

- patch: Fixed minor errors in the documentation

## 0.2.6

- patch: Updated contributing guidelines

## 0.2.5

- patch: Fix the COMMAND parameter validation

## 0.2.4

- patch: Update default S3_BUCKET name in readme.

## 0.2.3

- patch: Made wait interval configurable

## 0.2.2

- patch: Standardising README and pipes.yml.

## 0.2.1

- patch: Fixed incorrect reference to 'parameters' instead of 'variables' in the YAML definition.

## 0.2.0

- minor: Add support for the DEBUG flag.
- minor: Switch naming convention from tasks to pipes.

## 0.1.2

- minor: Use quotes for all pipes examples in README.md.

## 0.1.1

- minor: Restructure README.md to match user flow.

## 0.1.0

- minor: Initial release of Bitbucket Pipelines AWS Elastic Beanstalk deployment pipe.

