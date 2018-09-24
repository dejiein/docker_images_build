#!/bin/bash
jenkins_gerrit_credential=$1
workspace_path=$2

echo "### "
while IFS='' read -r line || [[ -n "$line" ]]; do
    directory_name=`dirname $line`

    cd ${workspace_path}/${directory_name}

    curl -k -u ${jenkins_gerrit_credential} -X POST -F "jenkinsfile=<Jenkinsfile" https://jenkins_URL/pipeline-model-converter/validate 2 > ${workspace_path}/error_jenkinsfile

    [ -s error_jenkinsfile ]&& ( echo "error in ${directory_name}/Jenkinsfile:\n `cat ${workspace_path}/error_jenkinsfile`"; rm -f ${workspace_path}/error_jenkinsfile; echo "1">${workspace_path}/error_check_jenkinsfile )

    cd ..

done < "${workspace_path}/jenkinsfile_proj_modified"

[ -s ${workspace_path}/error_check_jenkinsfile ] && ( rm -f ${workspace_path}/error_check_jenkinsfile ; exit 1 ) || ( rm -f ${workspace_path}/error_check_jenkinsfile ; exit 0 )
