pipeline {
    agent any

    environment {
        REPO_URL = 'http://wesalvator.com:3000/wesalvator/wesalvator.git'
        DOCKER_IMAGE = 'wamique00786/wesalvator'
        CONTAINER_NAME = 'wesalvator'
        DOCKER_BUILDKIT = '0'
        TIMESTAMP = new Date().format("yyyyMMddHHmmss")

        // Database connection details
        DATABASE_HOST = credentials('DATABASE_HOST')
        DATABASE_USER = credentials('DATABASE_USER')
        DATABASE_PASSWORD = credentials('DATABASE_PASSWORD')
        DATABASE_NAME = credentials('DATABASE_NAME')
        SECRET_KEY = credentials('SECRET_KEY')

        // Email recipient
        EMAIL_RECIPIENT = "pavansingh3000@gmail.com"
        
        // Slack API token for sending notifications
        SLACK_API_TOKEN = credentials('slack_api')  // This references your Slack API token
        
        SCANNER_HOME = tool 'SonarQube Scanner'
    }

    stages {
        stage('Git Clone') {
            steps {
                script {
                    try {
                        echo "Cloning repository from ${REPO_URL}"
                        git branch: 'main', url: "${REPO_URL}"
                    } catch (Exception e) {
                        error "Git Clone failed: ${e.message}"
                    }
                }
            }
        }
        
       
       
        stage('Docker Build') {
            steps {
                script {
                    try {
                        echo "Building Docker image..."
                        sh '''
                        docker build -t ${DOCKER_IMAGE}:${TIMESTAMP} . 
                        docker tag ${DOCKER_IMAGE}:${TIMESTAMP} ${DOCKER_IMAGE}:latest
                        '''
                    } catch (Exception e) {
                        error "Docker Build failed: ${e.message}"
                    }
                }
            }
        }
        stage('Trivy Scan Docker') {
            steps {
                script {
                    echo "Running Trivy scan..."
                    sh "trivy image ${DOCKER_IMAGE}:latest"
                }
            }       
        }

        stage('Docker Push') {
            steps {
                script {
                    try {
                        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD')]) {
                            echo "Pushing Docker image to Docker Hub..."
                            sh '''
                            export DOCKER_CONFIG=/tmp/.docker
                            mkdir -p $DOCKER_CONFIG
                            echo "{ \\"auths\\": { \\"https://index.docker.io/v1/\\": { \\"auth\\": \\"$(echo -n ${DOCKER_USER}:${DOCKER_PASSWORD} | base64)\\" } } }" > $DOCKER_CONFIG/config.json
                            docker push ${DOCKER_IMAGE}:latest
                            docker push ${DOCKER_IMAGE}:${TIMESTAMP}
                            '''
                        }
                    } catch (Exception e) {
                        error "Docker Push failed: ${e.message}"
                    }
                }
            }
        }
        
        

        stage('UAT Deployment') {
            steps {
                script {
                    withCredentials([
                        string(credentialsId: 'EMAIL_HOST_USER', variable: 'EMAIL_HOST_USER'),
                        string(credentialsId: 'EMAIL_HOST_PASSWORD', variable: 'EMAIL_HOST_PASSWORD'),
                        string(credentialsId: 'DEFAULT_FROM_EMAIL', variable: 'DEFAULT_FROM_EMAIL'),
                        string(credentialsId: 'ADMIN_EMAIL', variable: 'ADMIN_EMAIL')
                    ]) {
                        try {
                            echo "Deploying application container..."
                            sh '''
                            NETWORK_EXISTS=$(docker network ls --format "{{.Name}}" | grep -w wesalvator_network || true)
                            if [ -z "$NETWORK_EXISTS" ]; then
                                echo 'Creating Docker network...'
                                docker network create wesalvator_network
                            else
                                echo 'Network already exists. Skipping creation...'
                            fi

                            # Check if the app container exists and remove it
                            if [ "$(docker ps -a -q -f name=${CONTAINER_NAME})" ]; then
                                echo 'Stopping and removing existing app container...'
                                docker stop ${CONTAINER_NAME} || true
                                docker rm ${CONTAINER_NAME} || true
                            fi

                            echo 'Starting new app container...'
                            docker run -d --restart=always --name ${CONTAINER_NAME} --network wesalvator_network -p 8000:8000 \
                              -e DATABASE_HOST=${DATABASE_HOST} \
                              -e DATABASE_USER=${DATABASE_USER} \
                              -e DATABASE_PASSWORD=${DATABASE_PASSWORD} \
                              -e DATABASE_NAME=${DATABASE_NAME} \
                              -e SECRET_KEY=${SECRET_KEY} \
                              -e EMAIL_HOST="smtp.gmail.com" \
                              -e EMAIL_PORT="587" \
                              -e EMAIL_USE_TLS="True" \
                              -e EMAIL_HOST_USER="${EMAIL_HOST_USER}" \
                              -e EMAIL_HOST_PASSWORD="${EMAIL_HOST_PASSWORD}" \
                              -e DEFAULT_FROM_EMAIL="${DEFAULT_FROM_EMAIL}" \
                              -e ADMIN_EMAIL="${ADMIN_EMAIL}" \
                              -e GDAL_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu/libgdal.so \
                              -v static_volume:/app/staticfiles \
                              -v media_volume:/app/media \
                              ${DOCKER_IMAGE}:latest
                            docker system prune -a -f
                            '''
                        } catch (Exception e) {
                            error "UAT Deployment failed: ${e.message}"
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            script {
                echo "App deployed successfully."
                emailext(
                    subject: "Jenkins Pipeline: Deployment Successful 🎉",
                    body: """
                    <h2>✅ Application Deployed Successfully!</h2>
                    <p><b>Repository:</b> ${REPO_URL}</p>
                    <p><b>Docker Image:</b> ${DOCKER_IMAGE}:latest</p>
                    <p>🚀 The application is now live and running.</p>
                    <br>
                    <p>Regards,</p>
                    <p>Jenkins CI/CD</p>
                    """,
                    mimeType: "text/html",
                    to: "${EMAIL_RECIPIENT}"
                )
                
                // Slack Notification on success
                slackSend(
                    channel:  '#bugs-and-errors',  // Adjusted to your specific channel
                    message: "✅ Jenkins Pipeline: Deployment Successful! 🚀 Repository: ${REPO_URL}"
                )
            }
        }

        failure {
            script {
                def failedStage = currentBuild.rawBuild.getLog(50).find { it.contains("failed") }
                def logOutput = currentBuild.rawBuild.getLog(50).join("\n")
                echo "Pipeline failed at stage: ${failedStage}"
                echo "Error logs:\n${logOutput}"

                emailext(
                    subject: "Jenkins Pipeline: Deployment Failed ❌",
                    body: """
                    <h2>❌ Pipeline Failed</h2>
                    <p><b>Failed Stage:</b> ${failedStage}</p>
                    <p><b>Error Logs:</b></p>
                    <pre>${logOutput}</pre>
                    <br>
                    <p>Please check the Jenkins logs for more details.</p>
                    <p>Regards,</p>
                    <p>Jenkins CI/CD</p>
                    """,
                    mimeType: "text/html",
                    to: "${EMAIL_RECIPIENT}"
                )

                // Slack Notification on failure
                slackSend(
                    channel: '#bugs-and-errors',  // Adjusted to your specific channel
                    message: "❌ Jenkins Pipeline: Deployment Failed! 🚨 Failed Stage: ${failedStage}"
                )
            }
        }
    }
}
