def docker_version = "result_of_docker_version"
pipeline {
        agent {
                dockerfile {
                        dir 'build_images_docker/Dockerfiles_base'
                        label "jenkins_agent_name"
                        additionalBuildArgs  "--build-arg host_docker_version=\"${docker_version}\" --build-arg user_id=jenkins-slave_UID --build-arg group_id=jenkins-slave-GID"
                        args "-v /var/run/docker.sock:/var/run/docker.sock"
                }
        }
	stages {
		stage('get modified files list') {
			when {
                                anyOf {
				        environment name: 'GERRIT_EVENT_TYPE', value: 'patchset-created'
                                        environment name: 'GERRIT_EVENT_TYPE', value: 'draft-published' 
                                }
                        }

			environment {
				GERRIT_REST_API_CREDENTIALS='credential_defined_in_jenkins_to_connect_to_gerrit'
				CREDENTIALS = credentials("${env.GERRIT_REST_API_CREDENTIALS}")
			}
			steps {
				echo "${env.GERRIT_CHANGE_ID}"

				//REST API to get list of modified files
				sh "echo \"creates `pwd`/resultlistfiles\""

				sh "curl -vvv -u \"${env.CREDENTIALS}\" --verbose \"http://gerrit_URL/a/changes/${env.GERRIT_CHANGE_ID}/revisions/current/files/\" > `pwd`/resultlistfiles"
			
				//put the list of modified files in a file
				sh "ls -al; ./build_images_docker/Dockerfiles_base/check_modified_files.sh ${env.CREDENTIALS} `pwd` ; ls -al"
			}
		}

                stage('get source code') {
			when {
                                anyOf {
                                        environment name: 'GERRIT_EVENT_TYPE', value: 'patchset-created'
                                        environment name: 'GERRIT_EVENT_TYPE', value: 'draft-published'
                                }
                        }

			environment {
				GERRIT_CREDENTIALS='credential_defined_in_jenkins_to_connect_to_gerrit'
		                GERRIT_SRC="http://gerrit_project_URL"
			}
                        steps {
				dir('build') {
                    			checkout scm: [
                        		$class: 'GitSCM',
                        		branches: [[name: "${env.GERRIT_REFSPEC}"]],
                        		userRemoteConfigs: [[
                            			url: "${env.GERRIT_SRC}",
                            			credentialsId: "${GERRIT_CREDENTIALS}",
                            			refspec: "${env.GERRIT_REFSPEC}:${env.GERRIT_REFSPEC}"
                        		]],
                        		extensions: [
                            		[$class: 'BuildChooserSetting', buildChooser: [$class: 'GerritTriggerBuildChooser']]
                        		],
                    			], poll: false, changelog: false
                		}
			}
		}

		stage('Jenkinsfiles syntax validation') {
                        when {
                                anyOf {
                                        environment name: 'GERRIT_EVENT_TYPE', value: 'patchset-created'
                                        environment name: 'GERRIT_EVENT_TYPE', value: 'draft-published'
                                }
				expression { return fileExists("WORKSPACE_PATH/build/jenkinsfile_proj_modified") }
                        }
                        environment {
                                GERRIT_REST_API_CREDENTIALS='gerrit_rest_api_credential'
                                CREDENTIALS = credentials("${env.GERRIT_REST_API_CREDENTIALS}")
                        }
                        steps {
                                //validate all the modified Jenkinsfiles
                                sh "./build_images_docker/Dockerfiles_base/jenkinsfile_validation.sh ${env.CREDENTIALS} `pwd`/build ; rm -f jenkinsfile_modified  " 
                        }
                }

		stage('Dockerfiles syntax validation') {
                        when {
                                anyOf {
                                        environment name: 'GERRIT_EVENT_TYPE', value: 'patchset-created'
                                        environment name: 'GERRIT_EVENT_TYPE', value: 'draft-published'
                                }
                        }
                        environment {
                                GERRIT_REST_API_CREDENTIALS='gerrit_api_credential'
                                CREDENTIALS = credentials("${env.GERRIT_REST_API_CREDENTIALS}")
				docker_proj_Var = readFile('dockerfile_proj_modified').trim()
                        }
                        steps {
				//hadolint on the Dockerfile
				sh "/usr/local/bin/hadolint --version"	
	                        sh "/usr/local/bin/hadolint `pwd`/build/${env.docker_proj_Var} || false"
                        }
                }

		stage('get source code on gerrit merge') {
                        when {
				environment name: 'GERRIT_EVENT_TYPE', value: 'change-merged'
                        }

                        environment {
                                GERRIT_CREDENTIALS='gerrit_credential'
                                GERRIT_SRC="http://gerrit_project_URL"
                        }
                        steps {
                                dir('build') {
                                        checkout scm: [
                                        $class: 'GitSCM',
                                        branches: [[name: "${env.GERRIT_REFSPEC}"]],
                                        userRemoteConfigs: [[
                                                url: "${env.GERRIT_SRC}",
                                                credentialsId: "${GERRIT_CREDENTIALS}",
                                                refspec: "${env.GERRIT_REFSPEC}:${env.GERRIT_REFSPEC}"
                                        ]],
                                        extensions: [
                                        [$class: 'BuildChooserSetting', buildChooser: [$class: 'GerritTriggerBuildChooser']]
                                        ],
                                        ], poll: false, changelog: false
                                }
                        }
                }

		stage('prebuild step ') {
			when {
				environment name: 'GERRIT_EVENT_TYPE', value: 'change-merged'
			}
			environment {
                                GERRIT_REST_API_CREDENTIALS='gerrit_credential'
                                CREDENTIALS = credentials("${env.GERRIT_REST_API_CREDENTIALS}")
				NEXUS_JENKINS_CREDENTIALS = 'registry_credential'
                                NEXUS_CREDENTIALS = credentials("${env.NEXUS_JENKINS_CREDENTIALS}")
                                REGISTRY_PULL='registry_URL_for_pull'
                                REGISTRY_PUSH='registry_URL_for_push'
				GERRIT_PROJ_URL='http://gerrit_proj_URL'
				GERRIT_CREDENTIALS='gerrit_credential'
                        }
			steps {
				sh " rm -f `pwd`/resultlistfiles 2>/dev/null"

				sh "curl -vvv -u \"${env.CREDENTIALS}\" --verbose \"http://gerrit_URL/a/changes/${env.GERRIT_CHANGE_ID}/revisions/current/files/\" > `pwd`/resultlistfiles"
				
				//put the list of modified files in a file
				sh "./build_images_docker/Dockerfiles_base/check_modified_files.sh ${env.CREDENTIALS} `pwd`; echo 'AFTER check_modified_files.sh ##########'"

				//check if the modified Dockerfile is the basic one
				sh " (head -1 dockerfile_proj_modified |cut -d / -f1 | grep 'centos:7' > basicDockerfile) || (echo 'Non basic Dockerfile'; rm -f basicDockerfile 2>/dev/null)" 
								
				//calculate the new tag name to set and put it in the last_tag file
                                sh " ls -al ; build_images_docker/Dockerfiles_base/calculate_tag.sh `pwd`/build/`head -1 dockerfile_proj_modified |cut -d / -f1` `pwd`; ls -al"

				sh "echo ${NEXUS_CREDENTIALS_PSW} >pwnexus.txt "
				sh "cat last_tag"
			}
		}
		stage('basic dockerfile build') {
			when {
                                environment name: 'GERRIT_EVENT_TYPE', value: 'change-merged'
                        }
                        environment {
                                GERRIT_REST_API_CREDENTIALS='gerrit_rest_api_credential'
                                CREDENTIALS = credentials("${env.GERRIT_REST_API_CREDENTIALS}")
                                NEXUS_JENKINS_CREDENTIALS = 'nexus_credential'
                                NEXUS_CREDENTIALS = credentials("${env.NEXUS_JENKINS_CREDENTIALS}")
                                REGISTRY_PULL='registry_URL_for_pull'
                                REGISTRY_PUSH='registry_URL_for push'
                                GERRIT_PROJ_URL='http://gerrit_project_URL'
                                GERRIT_CREDENTIALS='gerrit_credential'
				pwnexus = readFile('pwnexus.txt').trim()
				oldtag = readFile('oldtag').trim()
				lasttag = readFile('last_tag').trim()
                        }
			steps {
				//login to the registry-mirror
				sh "echo ${env.pwnexus} |sudo /usr/local/bin/docker login --username ${env.NEXUS_JENKINS_CREDENTIALS} --password-stdin https://${env.REGISTRY_PULL}; exit"
				sh "echo ${env.pwnexus} |sudo /usr/local/bin/docker login --username ${env.NEXUS_JENKINS_CREDENTIALS} --password-stdin https://${REGISTRY_PUSH}; exit"
				script{
					if (fileExists('basicDockerfile')) {
						sh "echo 'Build of a basic Dockerfile!'"

						sh "sudo /usr/local/bin/docker rmi ${env.REGISTRY_PULL}/centos && ( sudo /usr/local/bin/docker pull ${env.REGISTRY_PULL}/centos || true ) ; sudo /usr/local/bin/docker build -t ${env.REGISTRY_PUSH}/ciaas/base_centos7:${env.lasttag} ./build/base_centos7/ ; sudo /usr/local/bin/docker tag ${env.REGISTRY_PUSH}/ciaas/base_centos7:${env.lasttag} ${env.REGISTRY_PUSH}/ciaas/base_centos7:latest"
						sh "sudo /usr/local/bin/docker push ${env.REGISTRY_PUSH}/ciaas/base_centos7:${env.lasttag} ; sudo /usr/local/bin/docker push ${env.REGISTRY_PUSH}/ciaas/base_centos7:latest"

                                        } else {
						sh "echo 'Non basic Dockerfile was modified!'"

						sh "[ \"${env.oldtag}\" == \"null\" ] && echo 'No old image'|| echo 'Old image:'${env.REGISTRY_PULL}'/ciaas/'`head -1 dockerfile_proj_modified |cut -d / -f1 `:${env.oldtag} "

                                        	sh "( sudo /usr/local/bin/docker pull ${env.REGISTRY_PULL}/ciaas/base_centos7:latest || true ) ; sudo /usr/local/bin/docker build -t ${env.REGISTRY_PUSH}/ciaas/`head -1 dockerfile_proj_modified |cut -d / -f1 `:${env.lasttag} ./build/`head -1 dockerfile_proj_modified |cut -d / -f1`/ ;  sudo /usr/local/bin/docker tag ${env.REGISTRY_PUSH}/ciaas/`head -1 dockerfile_proj_modified |cut -d / -f1 `:${env.lasttag} ${env.REGISTRY_PUSH}/ciaas/`head -1 dockerfile_proj_modified |cut -d / -f1 `:latest"

						sh "sudo /usr/local/bin/docker push ${env.REGISTRY_PUSH}/ciaas/`head -1 dockerfile_proj_modified |cut -d / -f1 `:${env.lasttag} ; sudo /usr/local/bin/docker push ${env.REGISTRY_PUSH}/ciaas/`head -1 dockerfile_proj_modified |cut -d / -f1 `:latest"
					}
                                 	
				}
				
                                //logout from nexus
                                sh "sudo /usr/local/bin/docker logout ${env.REGISTRY_PULL}"
                                sh "sudo /usr/local/bin/docker logout ${env.REGISTRY_PUSH}"
                                sh "rm -f pwnexus.txt"	
				
			}
			
		}
		stage('set tag in gerrit') {
                        when {
                                environment name: 'GERRIT_EVENT_TYPE', value: 'change-merged'
                        }
                        environment {
				GERRIT_PROJ_URL='http://gerrit_proj_URL'
                                GERRIT_CREDENTIALS='gerrit_credential'
				CREDENTIALS = credentials("${env.GERRIT_CREDENTIALS}")

				// Encode username and password to be able to use them with git
		                GERRIT_USER = sh (
                		    script: 'python -c "import urllib, sys; print urllib.quote(sys.argv[1])" ${CREDENTIALS_USR}',
		                    returnStdout: true
		                ).trim()
		                GERRIT_PWD = sh (
		                    script: 'python -c "import urllib, sys; print urllib.quote(sys.argv[1])" ${CREDENTIALS_PSW}',
		                    returnStdout: true
		                ).trim()
				tagVersion = readFile('last_tag').trim()
			}
			steps {
				//get source
                                dir('build') {
                                        git changelog: false, credentialsId: "${env.GERRIT_CREDENTIALS}", poll: false, url: "${env.GERRIT_PROJ_URL}"
                                }

		                echo "Git credential"
		                sh "echo http://${env.GERRIT_USER}:${env.GERRIT_PWD}@gerrit_URL > ~/.git-credentials"
		                sh "git config --global credential.helper store"
                                sh "cd build;git tag `head -1 ../dockerfile_proj_modified |cut -d / -f1 `-${env.tagVersion}; git push --tags"

			}
		}
	}
	post {
		always {
                        cleanWs()
                }
   	}
	
}
