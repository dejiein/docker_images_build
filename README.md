# CONTINUOUS INTEGRATION 

## Automatic build and push to a Nexus registry of Dockerfiles stored in Gerrit when a basic one is modified

  * Each Dockerfile is in a directory named like the corresponding image
  * Jenkinsfiles can be modified too, in this case, validate the syntax
  * The basic Dockerfile is based on centos:7, this one is used by the others
  * There must be a Jenkins pipeline which build this project, it must be triggered by Gerrit
