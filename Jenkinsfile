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
                sh 'echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list'
                sh "curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -"
                sh "sudo apt-get update && sudo apt-get install -y google-cloud-sdk"
                sh "gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS} --project=determined-ai"
                sh ". venv/bin/activate && make publish-dev"
            }
        }
    }
}
