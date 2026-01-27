pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'localhost:5000'
        APP_NAME = 'devops-practice'
        ENVIRONMENT = "${env.BRANCH_NAME == 'main' ? 'prod' : env.BRANCH_NAME == 'develop' ? 'staging' : 'dev'}"
    }
    
    parameters {
        choice(
            name: 'DEPLOY_ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Target deployment environment'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Skip test execution'
        )
        booleanParam(
            name: 'DEPLOY_INFRASTRUCTURE',
            defaultValue: false,
            description: 'Deploy infrastructure with Terraform'
        )
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo "🔄 Checking out code from ${env.BRANCH_NAME}"
                checkout scm
                
                script {
                    env.BUILD_VERSION = sh(
                        script: "echo ${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}",
                        returnStdout: true
                    ).trim()
                }
                
                echo "📦 Build version: ${env.BUILD_VERSION}"
            }
        }
        
        stage('Environment Setup') {
            steps {
                echo "🔧 Setting up environment: ${env.ENVIRONMENT}"
                
                script {
                    // Copy appropriate environment file
                    sh "cp .env.${env.ENVIRONMENT} .env"
                    
                    // Set build-specific variables
                    sh """
                        echo "BUILD_VERSION=${env.BUILD_VERSION}" >> .env
                        echo "BUILD_NUMBER=${env.BUILD_NUMBER}" >> .env
                        echo "GIT_COMMIT=${env.GIT_COMMIT}" >> .env
                    """
                }
            }
        }
        
        stage('Validate Configuration') {
            parallel {
                stage('Terraform Validate') {
                    steps {
                        echo "🔍 Validating Terraform configuration"
                        dir('terraform') {
                            sh 'terraform init -backend=false'
                            sh 'terraform validate'
                        }
                    }
                }
                
                stage('Ansible Validate') {
                    steps {
                        echo "🔍 Validating Ansible playbooks"
                        dir('ansible') {
                            sh 'ansible-playbook --syntax-check playbooks/site.yml'
                            sh 'ansible-playbook --syntax-check playbooks/deploy.yml'
                        }
                    }
                }
                
                stage('Docker Compose Validate') {
                    steps {
                        echo "🔍 Validating Docker Compose configuration"
                        sh """
                            docker-compose -f docker-compose.yml \\
                                          -f docker-compose.${env.ENVIRONMENT}.yml \\
                                          config > /dev/null
                        """
                    }
                }
            }
        }
        
        stage('Build Services') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                    changeRequest()
                }
            }
            
            parallel {
                stage('Build Frontend') {
                    steps {
                        echo "🏗️ Building web frontend"
                        script {
                            if (fileExists('services/web-frontend/Dockerfile')) {
                                dir('services/web-frontend') {
                                    sh """
                                        docker build -t ${DOCKER_REGISTRY}/${APP_NAME}-frontend:${BUILD_VERSION} .
                                        docker tag ${DOCKER_REGISTRY}/${APP_NAME}-frontend:${BUILD_VERSION} \\
                                                   ${DOCKER_REGISTRY}/${APP_NAME}-frontend:latest
                                    """
                                }
                            } else {
                                echo "⚠️ Frontend Dockerfile not found, skipping build"
                            }
                        }
                    }
                }
                
                stage('Build API Gateway') {
                    steps {
                        echo "🏗️ Building API Gateway"
                        script {
                            if (fileExists('services/api-gateway/Dockerfile')) {
                                dir('services/api-gateway') {
                                    sh """
                                        docker build -t ${DOCKER_REGISTRY}/${APP_NAME}-api:${BUILD_VERSION} .
                                        docker tag ${DOCKER_REGISTRY}/${APP_NAME}-api:${BUILD_VERSION} \\
                                                   ${DOCKER_REGISTRY}/${APP_NAME}-api:latest
                                    """
                                }
                            } else {
                                echo "⚠️ API Gateway Dockerfile not found, skipping build"
                            }
                        }
                    }
                }
                
                stage('Build Microservices') {
                    steps {
                        echo "🏗️ Building microservices"
                        script {
                            def services = ['learning-service', 'user-service', 'lab-service', 'assessment-service']
                            
                            services.each { service ->
                                if (fileExists("services/${service}/Dockerfile")) {
                                    dir("services/${service}") {
                                        sh """
                                            docker build -t ${DOCKER_REGISTRY}/${APP_NAME}-${service}:${BUILD_VERSION} .
                                            docker tag ${DOCKER_REGISTRY}/${APP_NAME}-${service}:${BUILD_VERSION} \\
                                                       ${DOCKER_REGISTRY}/${APP_NAME}-${service}:latest
                                        """
                                    }
                                } else {
                                    echo "⚠️ ${service} Dockerfile not found, skipping build"
                                }
                            }
                        }
                    }
                }
            }
        }
        
        stage('Test') {
            when {
                not { params.SKIP_TESTS }
            }
            
            parallel {
                stage('Unit Tests') {
                    steps {
                        echo "🧪 Running unit tests"
                        script {
                            // Run tests for each service if test files exist
                            def services = ['web-frontend', 'api-gateway', 'learning-service', 'user-service', 'lab-service', 'assessment-service']
                            
                            services.each { service ->
                                if (fileExists("services/${service}/package.json")) {
                                    dir("services/${service}") {
                                        sh 'npm test -- --run --reporter=junit --outputFile=test-results.xml || true'
                                    }
                                } else if (fileExists("services/${service}/requirements.txt")) {
                                    dir("services/${service}") {
                                        sh 'python -m pytest --junit-xml=test-results.xml || true'
                                    }
                                }
                            }
                        }
                    }
                    
                    post {
                        always {
                            // Collect test results
                            publishTestResults testResultsPattern: 'services/*/test-results.xml'
                        }
                    }
                }
                
                stage('Integration Tests') {
                    steps {
                        echo "🔗 Running integration tests"
                        script {
                            // Start test environment
                            sh """
                                docker-compose -f docker-compose.yml \\
                                              -f docker-compose.test.yml \\
                                              up -d --build
                            """
                            
                            // Wait for services to be ready
                            sh 'sleep 30'
                            
                            // Run integration tests
                            sh """
                                docker-compose -f docker-compose.yml \\
                                              -f docker-compose.test.yml \\
                                              exec -T api-gateway npm run test:integration || true
                            """
                        }
                    }
                    
                    post {
                        always {
                            // Clean up test environment
                            sh """
                                docker-compose -f docker-compose.yml \\
                                              -f docker-compose.test.yml \\
                                              down -v || true
                            """
                        }
                    }
                }
                
                stage('Security Scan') {
                    steps {
                        echo "🔒 Running security scans"
                        script {
                            // Scan Docker images for vulnerabilities
                            sh """
                                docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \\
                                    aquasec/trivy image ${DOCKER_REGISTRY}/${APP_NAME}-frontend:${BUILD_VERSION} || true
                            """
                        }
                    }
                }
            }
        }
        
        stage('Deploy Infrastructure') {
            when {
                anyOf {
                    params.DEPLOY_INFRASTRUCTURE
                    branch 'main'
                }
            }
            
            steps {
                echo "🏗️ Deploying infrastructure with Terraform"
                dir('terraform') {
                    sh """
                        terraform init
                        terraform plan -var-file="environments/${env.ENVIRONMENT}.tfvars" -out=tfplan
                        terraform apply tfplan
                    """
                }
            }
        }
        
        stage('Configure Services') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            
            steps {
                echo "⚙️ Configuring services with Ansible"
                dir('ansible') {
                    sh """
                        ansible-playbook -i inventories/${env.ENVIRONMENT}/hosts.yml \\
                                        playbooks/site.yml \\
                                        --extra-vars "app_version=${BUILD_VERSION}"
                    """
                }
            }
        }
        
        stage('Deploy Application') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            
            steps {
                echo "🚀 Deploying application to ${env.ENVIRONMENT}"
                
                script {
                    // Update image tags in environment file
                    sh """
                        sed -i 's/latest/${BUILD_VERSION}/g' .env
                    """
                    
                    // Deploy with Docker Compose
                    sh """
                        docker-compose -f docker-compose.yml \\
                                      -f docker-compose.${env.ENVIRONMENT}.yml \\
                                      up -d --no-build
                    """
                    
                    // Wait for services to be ready
                    sh 'sleep 60'
                    
                    // Health check
                    sh """
                        curl -f http://localhost:3000/health || exit 1
                        curl -f http://localhost:4000/health || exit 1
                    """
                }
            }
        }
        
        stage('Post-Deploy Tests') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            
            steps {
                echo "🧪 Running post-deployment tests"
                script {
                    // Run smoke tests
                    sh """
                        curl -f http://localhost:3000 || exit 1
                        curl -f http://localhost:4000/api/health || exit 1
                    """
                    
                    // Run Ansible deployment verification
                    dir('ansible') {
                        sh """
                            ansible-playbook -i inventories/${env.ENVIRONMENT}/hosts.yml \\
                                            playbooks/maintenance.yml \\
                                            --tags health-check
                        """
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 Pipeline completed for ${env.ENVIRONMENT} environment"
            
            // Archive artifacts
            archiveArtifacts artifacts: 'terraform/tfplan', allowEmptyArchive: true
            archiveArtifacts artifacts: '.env', allowEmptyArchive: true
            
            // Clean up workspace
            cleanWs()
        }
        
        success {
            echo "✅ Pipeline succeeded!"
            
            script {
                if (env.BRANCH_NAME == 'main') {
                    // Notify success for production deployments
                    slackSend(
                        channel: '#devops-alerts',
                        color: 'good',
                        message: "🚀 Production deployment successful! Version: ${BUILD_VERSION}"
                    )
                }
            }
        }
        
        failure {
            echo "❌ Pipeline failed!"
            
            // Notify failure
            slackSend(
                channel: '#devops-alerts',
                color: 'danger',
                message: "💥 Pipeline failed for ${env.BRANCH_NAME} - Build: ${BUILD_NUMBER}"
            )
        }
        
        unstable {
            echo "⚠️ Pipeline unstable!"
            
            slackSend(
                channel: '#devops-alerts',
                color: 'warning',
                message: "⚠️ Pipeline unstable for ${env.BRANCH_NAME} - Build: ${BUILD_NUMBER}"
            )
        }
    }
}