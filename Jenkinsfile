pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'localhost:5000'
        APP_NAME = 'devops-practice'
        ENVIRONMENT = "${env.BRANCH_NAME == 'main' ? 'prod' : env.BRANCH_NAME == 'develop' ? 'staging' : 'dev'}"
        BUILD_VERSION = "${env.BUILD_NUMBER}-${env.GIT_COMMIT?.take(7) ?: 'unknown'}"
        COMPOSE_PROJECT_NAME = "${APP_NAME}-${ENVIRONMENT}"
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
        booleanParam(
            name: 'RUN_SECURITY_SCAN',
            defaultValue: true,
            description: 'Run security scans on Docker images'
        )
        booleanParam(
            name: 'FORCE_REBUILD',
            defaultValue: false,
            description: 'Force rebuild of all Docker images'
        )
    }
    
    options {
        buildDiscarder(logRotator(
            numToKeepStr: '50',
            daysToKeepStr: '30',
            artifactNumToKeepStr: '10',
            artifactDaysToKeepStr: '7'
        ))
        timeout(time: 60, unit: 'MINUTES')
        timestamps()
        ansiColor('xterm')
        skipDefaultCheckout()
    }
    
    stages {
        stage('Checkout and Setup') {
            steps {
                echo "🔄 Checking out code from ${env.BRANCH_NAME}"
                checkout scm
                
                script {
                    // Set build metadata
                    env.BUILD_VERSION = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
                    env.BUILD_TIMESTAMP = new Date().format('yyyy-MM-dd HH:mm:ss')
                    
                    // Determine if this is a production deployment
                    env.IS_PRODUCTION = env.BRANCH_NAME == 'main' ? 'true' : 'false'
                }
                
                echo "📦 Build version: ${env.BUILD_VERSION}"
                echo "🏷️ Environment: ${env.ENVIRONMENT}"
                echo "🏭 Production build: ${env.IS_PRODUCTION}"
            }
        }
        
        stage('Environment Configuration') {
            steps {
                echo "🔧 Setting up environment: ${env.ENVIRONMENT}"
                
                script {
                    // Copy appropriate environment file
                    if (fileExists(".env.${env.ENVIRONMENT}")) {
                        sh "cp .env.${env.ENVIRONMENT} .env"
                    } else {
                        echo "⚠️ Environment file .env.${env.ENVIRONMENT} not found, using defaults"
                        sh "touch .env"
                    }
                    
                    // Set build-specific variables
                    sh """
                        echo "BUILD_VERSION=${env.BUILD_VERSION}" >> .env
                        echo "BUILD_NUMBER=${env.BUILD_NUMBER}" >> .env
                        echo "GIT_COMMIT=${env.GIT_COMMIT}" >> .env
                        echo "BUILD_TIMESTAMP=${env.BUILD_TIMESTAMP}" >> .env
                        echo "ENVIRONMENT=${env.ENVIRONMENT}" >> .env
                    """
                }
                
                // Archive environment configuration
                archiveArtifacts artifacts: '.env', fingerprint: true
            }
        }
        
        stage('Code Quality and Validation') {
            parallel {
                stage('Terraform Validate') {
                    steps {
                        echo "🔍 Validating Terraform configuration"
                        dir('terraform') {
                            sh '''
                                terraform init -backend=false
                                terraform validate
                                terraform fmt -check=true -diff=true
                            '''
                        }
                    }
                    post {
                        always {
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'terraform',
                                reportFiles: '*.html',
                                reportName: 'Terraform Validation Report'
                            ])
                        }
                    }
                }
                
                stage('Ansible Validate') {
                    steps {
                        echo "🔍 Validating Ansible playbooks"
                        dir('ansible') {
                            sh '''
                                ansible-lint playbooks/site.yml || true
                                ansible-lint playbooks/deploy.yml || true
                                ansible-playbook --syntax-check playbooks/site.yml
                                ansible-playbook --syntax-check playbooks/deploy.yml
                            '''
                        }
                    }
                    post {
                        always {
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'ansible',
                                reportFiles: '*.html',
                                reportName: 'Ansible Validation Report'
                            ])
                        }
                    }
                }
                
                stage('Docker Compose Validate') {
                    steps {
                        echo "🔍 Validating Docker Compose configuration"
                        script {
                            def composeFiles = [
                                "docker-compose.yml",
                                "docker-compose.${env.ENVIRONMENT}.yml"
                            ]
                            
                            def composeCmd = composeFiles.collect { "-f ${it}" }.join(' ')
                            
                            sh """
                                docker-compose ${composeCmd} config --quiet
                                docker-compose ${composeCmd} config > docker-compose-resolved.yml
                            """
                        }
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'docker-compose-resolved.yml', allowEmptyArchive: true
                        }
                    }
                }
                
                stage('Dockerfile Lint') {
                    steps {
                        echo "🔍 Linting Dockerfiles"
                        script {
                            def dockerfiles = sh(
                                script: "find . -name 'Dockerfile*' -type f",
                                returnStdout: true
                            ).trim().split('\n')
                            
                            dockerfiles.each { dockerfile ->
                                if (dockerfile) {
                                    echo "Linting ${dockerfile}"
                                    sh "docker run --rm -i hadolint/hadolint < ${dockerfile} || true"
                                }
                            }
                        }
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
                    params.FORCE_REBUILD
                }
            }
            
            parallel {
                stage('Build Frontend') {
                    steps {
                        echo "🏗️ Building web frontend"
                        script {
                            if (fileExists('services/frontend/Dockerfile')) {
                                dir('services/frontend') {
                                    sh """
                                        docker build \\
                                            --build-arg BUILD_VERSION=${BUILD_VERSION} \\
                                            --build-arg BUILD_TIMESTAMP="${BUILD_TIMESTAMP}" \\
                                            -t ${DOCKER_REGISTRY}/${APP_NAME}-frontend:${BUILD_VERSION} \\
                                            -t ${DOCKER_REGISTRY}/${APP_NAME}-frontend:latest \\
                                            .
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
                                        docker build \\
                                            --build-arg BUILD_VERSION=${BUILD_VERSION} \\
                                            -t ${DOCKER_REGISTRY}/${APP_NAME}-api:${BUILD_VERSION} \\
                                            -t ${DOCKER_REGISTRY}/${APP_NAME}-api:latest \\
                                            .
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
                                            docker build \\
                                                --build-arg BUILD_VERSION=${BUILD_VERSION} \\
                                                -t ${DOCKER_REGISTRY}/${APP_NAME}-${service}:${BUILD_VERSION} \\
                                                -t ${DOCKER_REGISTRY}/${APP_NAME}-${service}:latest \\
                                                .
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
        
        stage('Quality Gates') {
            when {
                not { params.SKIP_TESTS }
            }
            
            parallel {
                stage('Unit Tests') {
                    steps {
                        echo "🧪 Running unit tests"
                        script {
                            def services = [
                                'frontend': 'npm test -- --run --reporter=junit --outputFile=test-results.xml',
                                'api-gateway': 'npm test -- --run --reporter=junit --outputFile=test-results.xml',
                                'learning-service': 'npm test -- --run --reporter=junit --outputFile=test-results.xml',
                                'user-service': 'python -m pytest --junit-xml=test-results.xml --cov=. --cov-report=xml',
                                'lab-service': 'mvn test -Dmaven.test.failure.ignore=true',
                                'assessment-service': 'python -m pytest --junit-xml=test-results.xml --cov=. --cov-report=xml'
                            ]
                            
                            services.each { service, testCmd ->
                                if (fileExists("services/${service}")) {
                                    dir("services/${service}") {
                                        echo "Running tests for ${service}"
                                        sh "${testCmd} || true"
                                    }
                                }
                            }
                        }
                    }
                    
                    post {
                        always {
                            // Collect test results
                            publishTestResults testResultsPattern: 'services/*/test-results.xml,services/*/target/surefire-reports/*.xml'
                            
                            // Collect coverage reports
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'services',
                                reportFiles: '**/coverage/index.html,**/htmlcov/index.html',
                                reportName: 'Code Coverage Report'
                            ])
                        }
                    }
                }
                
                stage('Integration Tests') {
                    steps {
                        echo "🔗 Running integration tests"
                        script {
                            try {
                                // Start test environment
                                sh """
                                    docker-compose -f docker-compose.yml \\
                                                  -f docker-compose.test.yml \\
                                                  up -d --build
                                """
                                
                                // Wait for services to be ready
                                sh '''
                                    echo "Waiting for services to be ready..."
                                    timeout 120 bash -c 'until curl -f http://localhost:4000/health; do sleep 5; done'
                                '''
                                
                                // Run integration tests
                                sh """
                                    docker-compose -f docker-compose.yml \\
                                                  -f docker-compose.test.yml \\
                                                  exec -T api-gateway npm run test:integration || true
                                """
                                
                            } catch (Exception e) {
                                echo "Integration tests failed: ${e.getMessage()}"
                                currentBuild.result = 'UNSTABLE'
                            }
                        }
                    }
                    
                    post {
                        always {
                            // Collect integration test logs
                            sh """
                                docker-compose -f docker-compose.yml \\
                                              -f docker-compose.test.yml \\
                                              logs > integration-test-logs.txt || true
                            """
                            
                            archiveArtifacts artifacts: 'integration-test-logs.txt', allowEmptyArchive: true
                            
                            // Clean up test environment
                            sh """
                                docker-compose -f docker-compose.yml \\
                                              -f docker-compose.test.yml \\
                                              down -v --remove-orphans || true
                            """
                        }
                    }
                }
                
                stage('Security Scan') {
                    when {
                        params.RUN_SECURITY_SCAN
                    }
                    steps {
                        echo "🔒 Running security scans"
                        script {
                            def images = [
                                "${DOCKER_REGISTRY}/${APP_NAME}-frontend:${BUILD_VERSION}",
                                "${DOCKER_REGISTRY}/${APP_NAME}-api:${BUILD_VERSION}"
                            ]
                            
                            images.each { image ->
                                if (sh(script: "docker images -q ${image}", returnStdout: true).trim()) {
                                    echo "Scanning ${image}"
                                    sh """
                                        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \\
                                            aquasec/trivy image --format json --output ${image.replaceAll('[/:]', '_')}-scan.json ${image} || true
                                    """
                                }
                            }
                        }
                    }
                    
                    post {
                        always {
                            archiveArtifacts artifacts: '*-scan.json', allowEmptyArchive: true
                            
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: '.',
                                reportFiles: '*-scan.json',
                                reportName: 'Security Scan Report'
                            ])
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
                    script {
                        def tfVarsFile = "environments/${env.ENVIRONMENT}.tfvars"
                        
                        if (fileExists(tfVarsFile)) {
                            sh """
                                terraform init
                                terraform plan -var-file="${tfVarsFile}" -out=tfplan
                            """
                            
                            if (env.IS_PRODUCTION == 'true') {
                                input message: 'Deploy infrastructure to production?', ok: 'Deploy'
                            }
                            
                            sh 'terraform apply tfplan'
                        } else {
                            echo "⚠️ Terraform variables file ${tfVarsFile} not found, skipping infrastructure deployment"
                        }
                    }
                }
            }
            
            post {
                always {
                    archiveArtifacts artifacts: 'terraform/tfplan', allowEmptyArchive: true
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
                                        --extra-vars "app_version=${BUILD_VERSION}" \\
                                        --diff
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
                    echo "⏳ Waiting for services to be ready..."
                    sh '''
                        timeout 180 bash -c '
                            while ! curl -f http://localhost:3000/health 2>/dev/null; do
                                echo "Waiting for frontend..."
                                sleep 10
                            done
                            while ! curl -f http://localhost:4000/health 2>/dev/null; do
                                echo "Waiting for API..."
                                sleep 10
                            done
                        '
                    '''
                }
            }
        }
        
        stage('Post-Deploy Verification') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            
            steps {
                echo "🧪 Running post-deployment verification"
                script {
                    // Run smoke tests
                    def healthChecks = [
                        'Frontend': 'http://localhost:3000',
                        'API Gateway': 'http://localhost:4000/api/health',
                        'Grafana': 'http://localhost:3001/api/health',
                        'Prometheus': 'http://localhost:9090/-/healthy'
                    ]
                    
                    healthChecks.each { service, url ->
                        echo "Checking ${service}..."
                        sh "curl -f ${url} || exit 1"
                    }
                    
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
        
        stage('Performance Tests') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            
            steps {
                echo "⚡ Running performance tests"
                script {
                    // Basic load testing with curl
                    sh '''
                        echo "Running basic load test..."
                        for i in {1..10}; do
                            curl -s -o /dev/null -w "%{http_code} %{time_total}\\n" http://localhost:3000 &
                        done
                        wait
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 Pipeline completed for ${env.ENVIRONMENT} environment"
            
            // Archive build artifacts
            archiveArtifacts artifacts: '.env,docker-compose-resolved.yml', allowEmptyArchive: true
            
            // Collect Docker logs
            sh """
                docker-compose -f docker-compose.yml \\
                              -f docker-compose.${env.ENVIRONMENT}.yml \\
                              logs --no-color > docker-logs.txt || true
            """
            archiveArtifacts artifacts: 'docker-logs.txt', allowEmptyArchive: true
        }
        
        success {
            echo "✅ Pipeline succeeded!"
            
            script {
                def message = "✅ Pipeline succeeded for ${env.BRANCH_NAME}"
                message += "\\nVersion: ${BUILD_VERSION}"
                message += "\\nEnvironment: ${env.ENVIRONMENT}"
                message += "\\nBuild: ${BUILD_URL}"
                
                if (env.BRANCH_NAME == 'main') {
                    slackSend(
                        channel: '#devops-alerts',
                        color: 'good',
                        message: "🚀 Production deployment successful!\\n${message}"
                    )
                } else {
                    slackSend(
                        channel: '#devops-alerts',
                        color: 'good',
                        message: message
                    )
                }
            }
        }
        
        failure {
            echo "❌ Pipeline failed!"
            
            script {
                def message = "❌ Pipeline failed for ${env.BRANCH_NAME}"
                message += "\\nBuild: ${BUILD_NUMBER}"
                message += "\\nError: ${currentBuild.description ?: 'Unknown error'}"
                message += "\\nLogs: ${BUILD_URL}console"
                
                slackSend(
                    channel: '#devops-alerts',
                    color: 'danger',
                    message: message
                )
            }
        }
        
        unstable {
            echo "⚠️ Pipeline unstable!"
            
            slackSend(
                channel: '#devops-alerts',
                color: 'warning',
                message: "⚠️ Pipeline unstable for ${env.BRANCH_NAME} - Build: ${BUILD_NUMBER}\\nSome tests may have failed."
            )
        }
        
        cleanup {
            // Clean up Docker resources
            sh '''
                docker system prune -f --volumes || true
                docker image prune -f || true
            '''
        }
    }
}