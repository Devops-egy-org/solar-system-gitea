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

        stage('OWASP Dependecy Check') {
            steps {
                dependencyCheck additionalArguments: '''
                --scan \'./\'
                --out \'./\'
                --format \'All\'
                --prettyprint''', odcInstallation" 'OWASP-DepCheck-10'
            }
        }

    }
}