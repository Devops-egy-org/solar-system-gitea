def slackNotificationMethod(String buildStatus = 'STARTED') {
    buildStatus = buildStatus ?: 'SUCCESS'

    def color

    if (buildStatus == 'SUCCESS') {
        color = '#47ec05'
    } else if (buildStatus == 'UNSTABLE') {
        color = '#d5ee0d'
    } else {
        color = '#ec2805'
    }

    def msg = "${buildStatus}: `${env.JOB_NAME}` #${env.BUILD_NUMBER}:\n${env.BUILD_URL}"

    slackSend(color: color, message: msg)
}

pipeline {
    agent any

    tools {                         // Tools Section Used to used specific Version from any tool Installed at Jenkins 
        nodejs 'nodejs-22-6-0' 
    }
    environment {
       MONGO_URI = "mongodb+srv://supercluster.d83jj.mongodb.net/superData"
       MONGO_DB_CREDS = credentials('mango_db_credentils')
       MONGO_USERNAME = credentials('mango_db_user')
       MONGO_PASSWORD = credentials('mango_db_psw')
       GITHUB_TOKEN = credentials('github_token')
       K8S_TOKEN = credentials('k8s-token')
       K8S_SERVER = 'https://192.168.56.30:6443'
       SONAR_SCANNER_HOME = tool 'sonarqube-scanner-610'

    }


    stages {
        stage('Clean Workspace ') {
             steps {
                cleanWs()
                   }
        }
        stage('Checkout Code') {
             steps {
               checkout scm 
                   }
        }

        stage('Installing Dependencies') {
            options { timestamps() }
            steps {
                sh 'npm install --no-audit'
            }
        }
        stage('Dependency Scaning') {
            parallel {                  // It used to excute stages at same time Not depends on each other. 
                stage('NPM Dependency Audit') {
                    steps {
                        sh '''
                            npm audit --audit-level=critical || true
                            echo $?
                        '''
                    }
                }

                stage('OWASP Dependency Check') {
                    steps {
                        dependencyCheck additionalArguments: '''
                            --scan ./
                            --out ./
                            --format ALL
                            --prettyPrint
                            --disableYarnAudit
                        ''', odcInstallation: 'OWASP-DepCheck-10' 
                        dependencyCheckPublisher failedTotalCritical: 2, pattern: 'dependency-check-report.xml', stopBuild: true //Fail Build if there is 1 Critical at xml report 

                        publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'dependency-check-jenkins.html', reportName: 'Dependency check Html Report', reportTitles: '', useWrapperFileDirectly: true]) // Adding dependency-check-jenkins.html at Artifacts

                        junit allowEmptyResults: true, keepProperties: true, stdioRetention: '', testResults: 'dependency-check-junit.xml' // Puplish dependency-check-junit.xml to Junkins Test Results
                    }
                }
            }
        }
        stage('Unit Testing') {
            options { retry(2) }
            steps {
              sh 'echo $MONGO_DB_CREDS' 
              sh 'echo username - $MONGO_DB_CREDS_USR'
              sh 'echo password - $MONGO_DB_CREDS_PSW'
              sh 'npm test'
              junit allowEmptyResults: true, keepProperties: true, stdioRetention: '', testResults: 'test-results.xml'
                
            }
        }        
        stage('Code Coverage') {
           
            steps {
                   catchError(buildResult: 'SUCCESS', message: 'Oosp! it will fixed in future relases', stageResult: 'UNSTABLE') { // catchError will let me continue to the next stage if these faild 
                       sh 'npm run coverage ' //checking dependencies installed in  project and using catchError to prevent pip;e;ome to fail at minor error
                   }
                
                   publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'coverage/lcov-report', reportFiles: 'index.html', reportName: 'Code Coverage Html Report', reportTitles: '', useWrapperFileDirectly: true])
               
            }
        }
        stage ('SAST-SonaraQube ') { //SonarQube focuses on Source code quality and security analysis.
            steps {
                timeout(time: 60, unit: 'SECONDS') { // The timeout block in Jenkins is used to set a maximum time limit for executing a specific step or block of code within a pipeline. If the block exceeds the specified timeout, Jenkins will abort the execution of that block.
                    withSonarQubeEnv('sonar-qube-server') {  //Using Sonarqube Installation and Token & Host Url Part of installtion "Jenkins Settings"
                    sh 'echo $SONAR_SCANNER_HOME'
                    sh '''
                    $SONAR_SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectKey=solar-system-project \
                        -Dsonar.sources=app.js \
                        -Dsonar.Javascript.lcov.reportPaths=./coverage/lcov.info
                      

                    '''
                    }
                    waitForQualityGate abortPipeline: true //Wait For SonarQube analysis to be completed and return quality gate status
                }

            }
        }
        stage ('Build Docker Image') {
            when {
                    expression { env.BRANCH_NAME != 'main' }
                }
            steps {
                sh 'printenv'
                sh 'docker build -t muhamedk/solar-system:$GIT_COMMIT .'
            }
        }
        stage ('Trivy Vulnerability Scanner') { //Scanning docker image Using Trivy 
            when {
                    expression { env.BRANCH_NAME != 'main' }
                }
            steps {
                
                sh '''
                   trivy image muhamedk/solar-system:$GIT_COMMIT \
                        --severity LOW,MEDIUM,HIGH \
                        --exit-code 0 \
                        --quiet \
                        --format json -o trivy-image-MEDIUM-results.json 
                        

                    trivy image muhamedk/solar-system:$GIT_COMMIT \
                        --severity CRITICAL\
                        --exit-code 0 \
                        --quiet \
                        --format json -o trivy-image-CRITICAL-results.json
                ''' //Trivy didn't support Reports at Html or xml but you can generate the JSON report first and convert it to other formats with the convert subcommand.you can go to Docs For more. "For Testng i changed severity CRITICAL to 0"
            }
            post {
                always {
                    sh '''
                       trivy convert \
                             --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
                             --output trivy-image-MEDIUM-results.html trivy-image-MEDIUM-results.json

                       trivy convert \
                             --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
                             --output trivy-image-CRITICAL-results.html trivy-image-CRITICAL-results.json 

                        trivy convert \
                            --format template --template "@/usr/local/share/trivy/templates/junit.tpl" \
                            --output trivy-image-MEDIUM-results.xml trivy-image-MEDIUM-results.json 
                      
                        trivy convert \
                             --format template --template "@/usr/local/share/trivy/templates/junit.tpl" \
                             --output trivy-image-CRITICAL-results.xml trivy-image-CRITICAL-results.json 

                        
                    '''


                }
            }
        }
        stage ('Push Docker Image') { //Push Docker Image to Docker Registry
            when {
                    expression { env.BRANCH_NAME != 'main' }
                }
            steps {
                withDockerRegistry(credentialsId: 'docker-hub-credentials', url: "") {
                sh 'docker push muhamedk/solar-system:$GIT_COMMIT'
                }
            }
        }
        stage ('Deploy - AWS EC2 ') { //Deploy dockerization app via ssh Agent Plugin 
            when { //this is condection to run this stage at spific branch 
                branch 'feature/*'
            }
            steps {
              script{ // I used script block becouse Crovy did't understand if condectios and for loop
                    sshagent(['aws-dev-deploy-ec2-instance']) {
                        sh '''
                            ssh -o StrictHostKeyChecking=no ec2-user@18.227.105.220 "
                                if sudo docker ps -a | grep -q "solar-system"; then
                                    echo "Container found. Stopping and removing..."
                                    sudo docker stop solar-system && sudo docker rm solar-system
                                    echo "Container stopped and removed."
                                fi
                                    sudo docker run --name solar-system \
                                        -e MONGO_URI=$MONGO_URI \
                                        -e MONGO_USERNAME=$MONGO_USERNAME \
                                        -e MONGO_PASSWORD=$MONGO_PASSWORD \
                                        -p 3000:3000 -d muhamedk/solar-system:$GIT_COMMIT
                            "
                        '''
                    }
                }    

            }
        }
        stage ('Integration Testing AWS-EC2') {
            when { //this is condection to run this stage at spific branch 
                branch 'feature/*'
            }
            steps {
                sh 'printenv | grep -i branch'
                withAWS(credentials: 'aws-s3-ec2-lambda-cerds', region: 'us-east-2') {
                    sh '''
                       bash integration-testing.sh
                    '''

                }
            }
        }
        stage ('K8S Updte Image Tag') {
            when {
                branch 'PR*'
            }
            steps {
                sh 'git clone -b main https://github.com/Devops-egy-org/solar-system-gitops-argocd'
                dir("solar-system-gitops-argocd/kubernetes") { //cahange the current dir
                    sh '''
                       #### Replace Docker Tage #####
                       git checkout main 
                       git checkout -b feature-$BUILD_ID
                       sed -i "s#muhamedk.*#muhamedk/solar-system:$GIT_COMMIT#g" deployment.yml
                       cat deployment.yml

                       #### Commit and Push to Feature Branch ####
                       git config --global user.email "jenkins@solar.com"
                       git remote set-url origin https://$GITHUB_TOKEN@github.com/Devops-egy-org/solar-system-gitops-argocd
                       git add .
                       git commit -am "Update Docker Image"
                       git push -u origin feature-$BUILD_ID
   
                     ''' 
                    
                }
            }

        }
        stage ('K8S - Rise PR') {//Rais a PR after change the Image Tage 
            when {
                branch 'PR*'
            }
            steps {
                  sh '''
                    curl -L \
                        -X POST \
                        -H "Accept: application/vnd.github+json" \
                        -H "Authorization: Bearer $GITHUB_TOKEN" \
                        -H "X-GitHub-Api-Version: 2022-11-28" \
                        https://api.github.com/repos/Devops-egy-org/solar-system-gitops-argocd/pulls \
                        -d \'{
                            "title": "Update Docker Image",
                            "body": "Update docker image in deployment manifest!",
                            "head": "feature-'${BUILD_ID}'",
                            "base": "main"
                        }\'
                    '''

                }

        }
        stage ('APP Deployed?') {//Make Sure Merging happen to Mainfast K8s main branch befor run web Interface this stage will Wait for interactive input For 1 Day after that it will fail! 
            when {
                branch 'PR*'
            }
            steps {
                timeout(time: 1, unit: 'DAYS') {
                    input message: 'is the PR Merges and ArgoCD Synced?', ok: 'Yes! PR is Merged and ArgoCD Application is Synced'
                }
            }
        }
        stage ('DAST - OWASP ZAP ') { //DAST'Dynamic Application Security Testing' Tools like "ZED Attack Proxy" Scan the app web interfaces and API insted of scorce code to detect common vulnerabilities Like SQL injection, Cross-Site Scripting and many 
           when {
            branch 'PR*'
           }
           steps {
                sh '''
                    chmod 777 $(pwd)
                    docker run -v $(pwd):/zap/wrk/:rw ghcr.io/zaproxy/zaproxy zap-api-scan.py \
                    -t http://192.168.56.21:30000/api-docs/ -f openapi \
                    -r zap_report.html \
                    -w zap_report.md \
                    -J zap_json_report.json \
                    -x zap_xml_report.xml \
                    -c zap_ignore_rules
                ''' 
           }
           

        }
        stage ('Upload - AWS S3') { //Uploade Reports To S3 Bucket
            when {
                branch 'PR*'
            }
            steps {
                withAWS(credentials: 'aws-s3-ec2-lambda-cerds', region: 'us-east-2') {
                    sh '''
                    ls -ltr 
                    mkdir reports-$BUILD_ID
                    cp -rf coverage/ reports-$BUILD_ID/
                    cp dependency*.* test-results.xml trivy*.* reports-$BUILD_ID/
                    ls -ltr reports-$BUILD_ID/
                    '''
                    s3Upload( //Using AWS Steps Plugin 
                        file:"reports-$BUILD_ID", 
                        bucket:"solar-system-jenkins-reports-bucket-s3", 
                        path:"jenkins-$BUILD_ID/")
                }
            }
        }
        stage ('Deploy to Prod?') {
                when {
                    anyOf{
                        branch 'main'
                        branch 'PR*' 
                    }
                    
                }
            steps {
                timeout(time: 1, unit: 'DAYS') {
                    input message: 'Deploy to Production?', ok: 'Yes! Let us try this on production', submitter: 'admin' 
                }
            }
        }
        stage ('Lambda - S3 Upload & Deploy') {
            when { 
               branch 'main'
            }
            steps {
               withAWS(credentials: 'aws-s3-ec2-lambda-cerds', region: 'us-east-2') {
                script {
                 sh '''
                    tail -5 app.js
                    echo "***************************************************"
                    sed -i "/^app\\.listen(3000/ s/^/\\/\\//" app.js
                    sed -i "/^module.exports = app/ s/^/\\/\\//" app.js 
                    sed -i "/^\\/\\/module.exports.handler = serverless(app)/ s/\\/\\/module.exports.handler = serverless(app)/module.exports.handler = serverless(app)/" app.js
                    echo "***************************************************"
                    tail -5 app.js 
                 '''
                }
                sh '''
                   echo "*****Zip App******"
                   zip -qr solar-system-lambda-$BUILD_ID.zip app* package* index.html node*
                   ls -ltr solar-system-lambda-$BUILD_ID.zip
                '''
                sh '''
                   aws s3 cp solar-system-lambda-$BUILD_ID.zip s3://solar-system-lambda-bucket-s3/solar-system-lambda-$BUILD_ID.zip
                '''
                sh '''
                   aws lambda update-function-configuration \
                    --function-name solar-system-function \
                    --environment "Variables={
                    MONGO_USERNAME=$MONGO_USERNAME,
                    MONGO_PASSWORD=$MONGO_PASSWORD,
                    MONGO_URI=$MONGO_URI
                    }"
                '''

                sh '''
                   aws lambda update-function-code \
                   --function-name solar-system-function \
                   --s3-bucket solar-system-lambda-bucket-s3 \
                   --s3-key solar-system-lambda-$BUILD_ID.zip
                
                '''

               }
            }
        }
        stage ('Lambda - Invoke Function') {
            when {
                branch 'main'
            }
            steps {
                withAWS(credentials: 'aws-s3-ec2-lambda-cerds', region: 'us-east-2') {
                    sh '''
                       sleep 30s
                       function_url=$(aws lambda  get-function-url-config --function-name solar-system-function  | jq -r '.FunctionUrl | sub("/$"; "")')
                       curl -Is $function_url/live | grep -i "200 OK"
                    
                    '''
                }

            }
        }
        


    }  
  

    post {
        always { 
            slackNotificationMethod("${currentBuild.result}")
            script {
                if (fileExists('solar-system-gitops-argocd')) {
                    sh 'rm -rf solar-system-gitops-argocd'
                }
            }
            //Puplish junit.xml to Junkins Test Result
            junit allowEmptyResults: true, keepProperties: true, stdioRetention: '', testResults: 'dependency-check-junit.xml' // 

            junit allowEmptyResults: true, keepProperties: true, stdioRetention: '', testResults: 'test-results.xml'

            junit allowEmptyResults: true, keepProperties: true, stdioRetention: '', testResults: 'trivy-image-MEDIUM-results.xml'

            junit allowEmptyResults: true, keepProperties: true, stdioRetention: '', testResults: 'trivy-image-CRITICAL-results.xml'




            //Puplish Html to Junkins Artifactes 
            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'trivy-image-MEDIUM-results.html', reportName: 'trivy-image-MEDIUM-results Html Report', reportTitles: '', useWrapperFileDirectly: true])

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'trivy-image-CRITICAL-results.html', reportName: 'trivy-image-CRITICAL-results Html Report', reportTitles: '', useWrapperFileDirectly: true])
             
            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'dependency-check-jenkins.html', reportName: 'Dependency check Html Report', reportTitles: '', useWrapperFileDirectly: true]) // Adding dependency-check-jenkins.html at Artifacts

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'zap_report.html', reportName: 'DAST - OWASP ZAP Report', reportTitles: '', useWrapperFileDirectly: true])


            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'coverage/lcov-report', reportFiles: 'index.html', reportName: 'Code Coverage Html Report', reportTitles: '', useWrapperFileDirectly: true])

            




        }
    }
}