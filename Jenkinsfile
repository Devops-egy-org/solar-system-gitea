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
       SONAR_SCANNER_HOME = tool 'sonarqube-scanner-610'
    }


    stages {
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
                            npm audit --audit-level=critical
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
                        dependencyCheckPublisher failedTotalCritical: 1, pattern: 'dependency-check-report.xml', stopBuild: true //Fail Build if there is 1 Critical at xml report 

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
        stage ('SAST-SonaraQube') { //SonarQube focuses on code quality and security analysis.
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
            steps {
                sh 'printenv'
                sh 'docker build -t muhamedk/solar-system:$GIT_COMMIT .'
            }
        }
    }

    post {
        always {
            junit allowEmptyResults: true, keepProperties: true, stdioRetention: '', testResults: 'dependency-check-junit.xml' // Puplish dependency-check-junit.xml to Junkins Test Result
            junit allowEmptyResults: true, keepProperties: true, stdioRetention: '', testResults: 'test-results.xml'

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'dependency-check-jenkins.html', reportName: 'Dependency check Html Report', reportTitles: '', useWrapperFileDirectly: true]) // Adding dependency-check-jenkins.html at Artifacts

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'coverage/lcov-report', reportFiles: 'index.html', reportName: 'Code Coverage Html Report', reportTitles: '', useWrapperFileDirectly: true])


        }
    }
}


