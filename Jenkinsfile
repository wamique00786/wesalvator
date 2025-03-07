pipeline {
    agent any

    environment {
        REPO_URL = 'http://wesalvator.com:3000/wesalvator/wesalvator.git'
        DOCKER_IMAGE = 'wamique00786/wesalvator'
        CONTAINER_NAME = 'wesalvator'
        DOCKER_BUILDKIT = '0'

        // Database connection details
        DATABASE_HOST = credentials('DATABASE_HOST')
        DATABASE_USER = credentials('DATABASE_USER')
        DATABASE_PASSWORD = credentials('DATABASE_PASSWORD')
        DATABASE_NAME = credentials('DATABASE_NAME')
        SECRET_KEY = credentials('SECRET_KEY')

        // Email recipient
        EMAIL_RECIPIENT = "pavansingh3000@gmail.com"

        // Slack API token
        SLACK_API_TOKEN = credentials('slack_api')

        SCANNER_HOME = tool 'SonarQube Scanner'
    }

    stages {
        stage('Set Timestamp') {
            steps {
                script {
                    env.TIMESTAMP = sh(script: 'date +%Y%m%d%H%M%S', returnStdout: true).trim()
                }
            }
        }

        stage('Git Clone') {
            steps {
                script {
                    withCredentials([usernameColonPassword(credentialsId: 'Gitea', variable: 'GITEA_CREDENTIALS')]) {
                        echo "Cleaning workspace before cloning..."
                        sh 'rm -rf ./* ./.??*'  // Ensures all files and hidden directories are deleted // Remove all files including any previous .git directory
                        echo "Cloning private repository from http://wesalvator.com:3000/wesalvatore/wesalvator.git"
                        sh '''
                        git clone http://${GITEA_CREDENTIALS}@wesalvator.com:3000/wesalvatore/wesalvator.git .
                        '''
                    }
                }
            }
        }
       /*
        stage('SonarQube Analysis') {
            steps {
                script {
                    withSonarQubeEnv('sonar-server') {
                        sh """
                            ${SCANNER_HOME}/bin/sonar-scanner \
                            -Dsonar.projectKey=wesalvator \
                            -Dsonar.projectName=wesalvator \
                            -Dsonar.sources=. \
                            -Dsonar.qualitygate.wait=true
                        """
                        sh 'cp .scannerwork/report-task.txt sonar-report.json || echo "{}" > sonar-report.json'
                    }
                }
            }
        }
        */
        stage('Docker Build') {
            steps {
                script {
                    try {
                        echo "Building Docker image..."
                        sh """
                        docker build -t ${DOCKER_IMAGE}:${TIMESTAMP} . 
                        docker tag ${DOCKER_IMAGE}:${TIMESTAMP} ${DOCKER_IMAGE}:latest
                        """
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
                    sh "trivy image ${DOCKER_IMAGE}:latest -f json -o trivy-report.json || echo '{}' > trivy-report.json"
                }
            }       
        }

        stage('Docker Push') {
            steps {
                script {
                    try {
                        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD')]) {
                            echo "Pushing Docker image to Docker Hub..."
                            sh """
                            echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USER}" --password-stdin
                            docker push ${DOCKER_IMAGE}:latest
                            docker push ${DOCKER_IMAGE}:${TIMESTAMP}
                            """
                        }
                    } catch (Exception e) {
                        error "Docker Push failed: ${e.message}"
                    }
                }
            }
        }
        /*
        stage('Send Trivy and SonarQube Reports to Slack') {  
            steps {
                script {
                    echo "Sending Trivy scan and SonarQube report to Slack..."
                    def trivyReportJson = readFile('trivy-report.json').take(4000)
                    def sonarReportJson = readFile('sonar-report.json').take(4000)
                    
                    slackSend(channel: '#bugs-and-errors', message: "🔍 *Trivy Security Scan Report*:\n```${trivyReportJson}```")
                    slackSend(channel: '#bugs-and-errors', message: "🛠 *SonarQube Bug Report*:\n```${sonarReportJson}```")
                }
            }
        }
        */

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
                              -v static_volume:/usr/share/nginx/html/static \
                              -v media_volume:/usr/share/nginx/html/media \
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
            }
        }
    }
}