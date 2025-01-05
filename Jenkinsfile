pipeline {
    agent any

    tools {
        nodejs 'nodejs-22-6-0' // Ensure this tool is configured in Jenkins
    }

    stages {
        stage('Installing Dependencies') {
            steps {
                sh 'npm install --no-audit'
            }
        }

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
                ''', odcInstallation: 'OWASP-DepCheck-10' // Corrected syntax
            }
        }
    }
}