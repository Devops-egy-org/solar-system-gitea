pipeline {
    agent any

    tools {
        nodejs 'nodejs-22-6-0'
    }


    stages {
        stage('Installing  Dependencies'){
            steps{
                sh 'npm install --no-audit'
            }
        }

        stage('NMP Dependency Audit') {
            steps {
                sh '''
                   npm audit --audit-level=critical
                   echo $? 
                '''
            }
        }

    }
}