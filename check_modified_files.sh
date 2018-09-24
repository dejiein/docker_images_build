#!/bin/bash
jenkins_gerrit_credential="$1"
rootpath="$2"
dockerfile_num=0
jenkinsfile_num=0

echo "############## check_modified_files.sh   ############"
rm -f ${rootpath}/modifiedfiles ${rootpath}/completelistfiles 2>/dev/null

echo "+++ cat ${rootpath}/resultlistfiles / creates ${rootpath}/completelistfiles "
lignes=`cat ${rootpath}/resultlistfiles |grep "\": {" > ${rootpath}/completelistfiles`

#get in a file the list of modified files except the commit one
echo "+++ cat ${rootpath}/completelistfiles / creates ${rootpath}/modifiedfiles "
echo "$(tail -n +2 ${rootpath}/completelistfiles)" > ${rootpath}/modifiedfiles

[ -f ${rootpath}/jenkinsfile_modified ] && rm -f ${rootpath}/jenkinsfile_modified
[ -f ${rootpath}/jenkinsfile_proj_modified ] && rm -f ${rootpath}/jenkinsfile_proj_modified
[ -f ${rootpath}/dockerfile_proj_modified ] && rm -f ${rootpath}/dockerfile_proj_modified

cat ${rootpath}/modifiedfiles

while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "$line"
    fileline=`echo $line |cut -d \" -f2`
    
    echo "fileline: $fileline"
    filename=`basename $fileline`
    echo $filename
    directname=`dirname $fileline`
    echo $directname
    
    case $filename in
        Jenkinsfile) echo ">>>>>>>>>>Jenkinsfile"
		let jenkinsfile_num++
		echo "$jenkinsfile_num">${rootpath}/jenkinsfile_modified
		echo "$line" >>${rootpath}/jenkinsfile_proj_modified
		;;
        Dockerfile) echo ">>>>>>>>>>>>>>>>Dockerfile"
		let dockerfile_num++
		echo "${directname}/${filename}" >>${rootpath}/dockerfile_proj_modified
		ls -al ${rootpath}/dockerfile_proj_modified
		echo "dockerfile_num : $dockerfile_num"
                ;;
        *) echo "Other file was modified!"
	    	;;
    esac
    if [ $dockerfile_num -gt 1 ]
    then
        echo "Dockerfiles must be commited separately!"
	cat ${rootpath}/modifiedfiles
	echo "Number of modified Dockerfiles: $dockerfile_num"
	exit 1
    else
        echo ">>> Dockerfile modified: `head -1 ${rootpath}/dockerfile_proj_modified`"
    fi
    if [ $jenkinsfile_num -gt 1 ]
    then
	echo "Jenkinsfiles must be commited separately!"
	exit 1
    else
        echo ">>> Jenkinsfile modified: `head -1 ${rootpath}/dockerfile_proj_modified`"
    fi
done < "${rootpath}/modifiedfiles"
if [ $jenkinsfile_num -eq 0 ] && [ $dockerfile_num -eq 0 ]; then
    echo "Neither a Dockerfile nor a Jenkinsfile was modified!"
    exit 1
fi
echo "+++ cat ${rootpath}/dockerfile_proj_modified"
rm -f ${rootpath}/completelistfiles ${rootpath}/resultlistfiles

