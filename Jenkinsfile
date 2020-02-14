pipeline {
    agent { label 'general' }
    environment {
        GOOGLE_APPLICATION_CREDENTIALS = "/home/ubuntu/gcp-creds.json"
    }
    stages {
        stage('Build and Push') {
            steps {
                sh "make build"
                // Install ansible onto AMI.
                sh 'virtualenv --python="$(command -v python3.6)" --no-site-packages venv'
                sh "venv/bin/python -m pip install ansible"
                sh "cat /home/ubuntu/docker-hub-password.txt | docker login -u determinedaidev --password-stdin"
                sh ". venv/bin/activate && make publish-dev"
            }
        }
    }
}
