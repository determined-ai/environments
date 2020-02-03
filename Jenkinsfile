dockerLogin = "\$(AWS_DEFAULT_REGION=\$(ec2metadata --availability-zone | sed 's/.\$//') aws ecr get-login --no-include-email)"

pipeline {
    agent { label 'general' }
    stages {
        stage('Build and Push') {
            steps {
                sh "${dockerLogin}"
                sh "make build"
                sh "make publish"
            }
        }
    }
}
