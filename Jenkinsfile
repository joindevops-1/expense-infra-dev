pipeline {
    agent {
        label 'AGENT-1'
    }
    options {
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()

        ansiColor('xterm')
    }
    parameters{
        choice(name: 'action', choices: ['Apply', 'Destroy'], description: 'Pick something')
    }
  
    stages {
        stage('Init') {
            when {
                params.action == 'Apply'
            }
            steps {
                sh """
                    cd 01-vpc
                    terraform init -reconfigure
                """
            }
        }
        stage('Plan') {
            when {
                params.action == 'Apply'
            }
            steps {
                sh """
                    cd 01-vpc
                    terraform plan
                """
            }
        }
        stage('Deploy') {
            input {
                message "Should we continue?"
                ok "Yes, we should."
            }
            when {
                params.action == 'Apply'
            }
            steps {
                sh """
                cd 01-vpc
                terraform apply -auto-approve
                """
            }
        }
        stage('Destroy') {
            input {
                message "Should we continue?"
                ok "Yes, we should."
            }
            when {
                params.action == 'Destroy'
            }
            steps {
                sh """
                cd 01-vpc
                terraform apply -auto-approve
                """
            }
        }
    }
    post { 
        always { 
            echo 'I will always say Hello again!'
        }
        success { 
            echo 'I will run when pipeline is success'
        }
        failure { 
            echo 'I will run when pipeline is failure'
        }
    }
}