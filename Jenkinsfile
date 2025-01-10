pipeline {
    agent any

    tools {                         // Tools Section used to used specific Version from any tool Installed at Jenkins 
        nodejs 'nodejs-22-6-0' 
    }
    environment {
       MONGO_URI = "mongodb+srv://supercluster.d83jj.mongodb.net/superData"
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
                        ''', odcInstallation: 'OWASP-DepCheck-10' 
                        dependencyCheckPublisher failedTotalCritical: 1, pattern: 'dependency-check-report.xml', stopBuild: true //Fail Build if there is 1 Critical at xml report 

                        publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'dependency-check-jenkins.html', reportName: 'HTML dependency-check-jenkins.html', reportTitles: '', useWrapperFileDirectly: true]) // Adding dependency-check-jenkins.html at Artifacts

                        junit allowEmptyResults: true, keepProperties: true, stdioRetention: '', testResults: 'dependency-check-junit.xml' // Puplish dependency-check-junit.xml to Junkins Test Results
                    }
                }
            }
        }
        stage('Unit Testing') {
            options { retry(2) }
            steps {
                withCredentials([usernamePassword(credentialsId: 'mango-db-credentils', passwordVariable: 'MONGO_PASSWORD', usernameVariable: 'MONGO_USERNAME')]) {
                     sh 'npm test'
                }
                junit allowEmptyResults: true, keepProperties: true, stdioRetention: '', testResults: 'test-results.xml'
            }
        }        
        stage('Code Coverage') {
           
            steps {
                withCredentials([usernamePassword(credentialsId: 'mango-db-credentils', passwordVariable: 'MONGO_PASSWORD', usernameVariable: 'MONGO_USERNAME')]) {
                   catchError(buildResult: 'SUCCESS', message: 'Oosp! it will fixed in future relases', stageResult: 'UNSTABLE') { // catchError will let me contine to the next stage if these faild 
                       sh 'npm run coverage '
                   }
                }
               
            }
        } 
    }
}