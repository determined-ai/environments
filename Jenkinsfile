pipeline {
    agent { label 'general' }
    environment {
        GOOGLE_APPLICATION_CREDENTIALS = credentials('gcp-vm-image-build-creds')
        DET_DOCKERHUB_CREDS = credentials('dockerhub-determinedai-dev')
    }
    stages {
        stage('Build and Push') {
            steps {
                sh "docker login -u ${env.DET_DOCKERHUB_CREDS_USR} -p ${env.DET_DOCKERHUB_CREDS_PSW}"
                sh "make build"
                // Install ansible onto AMI.
                sh 'virtualenv --python="$(command -v python3.6)" --no-site-packages venv'
                sh "venv/bin/python -m pip install ansible"
                sh 'echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list'
                sh "curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -"
                sh "sudo apt-get update && sudo apt-get install -y google-cloud-sdk"
                sh "gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS} --project=determined-ai"
                sh ". venv/bin/activate && make publish"
            }
        }
    }
}
