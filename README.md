# DossierCloudFormationRuby

Until the `cloudformation-template-generator` scala library merges the [CodePipeline and CodeBuild][] pull request, it
is unable to meet the requirements to build the Dossier system's CloudFormation template. Thus, for now, it is quickly
implemented in Ruby.

[CodePipeline and CodeBuild]: https://github.com/MonsantoCo/cloudformation-template-generator/pull/134

## Usage

To build the CloudFormation template run:
```bash
  ./bin/DossierCloudFormationRuby
```
