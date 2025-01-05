pipeline {
    agent any

    tools {                         // Tools Section used to used specific Version from any tool Installed at Jenkins 
        nodejs 'nodejs-22-6-0' 
    }

    stages {
        stage('Installing Dependencies') {
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
                    }
                }
            }
        }
    }
}