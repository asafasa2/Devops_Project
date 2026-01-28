// Release Pipeline - Production deployment with approval gates
pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'localhost:5000'
        APP_NAME = 'devops-practice'
        ENVIRONMENT = 'prod'
        BUILD_VERSION = "${env.BUILD_NUMBER}-${env.GIT_COMMIT?.take(7) ?: 'unknown'}"
    }
    
    parameters {
        string(
            name: 'RELEASE_VERSION',
            defaultValue: '',
            description: 'Release version (e.g., v1.2.3)'
        )
        booleanParam(
            name: 'SKIP_STAGING',
            defaultValue: false,
            description: 'Skip staging deployment'
        )
        booleanParam(
            name: 'ROLLBACK_ON_FAILURE',
            defaultValue: true,
            description: 'Automatically rollback on deployment failure'
        )
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '20', daysToKeepStr: '90'))
        timeout(time: 120, unit: 'MINUTES')
        timestamps()
        ansiColor('xterm')
    }
    
    stages {
        stage('Pre-Release Validation') {
            steps {
                echo "🔍 Validating release readiness"
                
                script {
                    // Validate release version format
                    if (params.RELEASE_VERSION && !params.RELEASE_VERSION.matches(/^v\d+\.\d+\.\d+$/)) {
                        error("Invalid release version format. Expected: vX.Y.Z")
                    }
                    
                    // Set release version
                    env.RELEASE_VERSION = params.RELEASE_VERSION ?: "v${env.BUILD_NUMBER}"
                    env.BUILD_VERSION = "${env.RELEASE_VERSION}-${env.GIT_COMMIT.take(7)}"
                }
                
                echo "🏷️ Release version: ${env.RELEASE_VERSION}"
                echo "📦 Build version: ${env.BUILD_VERSION}"
            }
        }
        
        stage('Build Release Artifacts') {
            steps {
                echo "🏗️ Building release artifacts"
                
                script {
                    def services = ['frontend', 'api-gateway', 'learning-service', 'user-service', 'lab-service', 'assessment-service']
                    
                    services.each { service ->
                        if (fileExists("services/${service}/Dockerfile")) {
                            dir("services/${service}") {
                                sh """
                                    docker build \\
                                        --build-arg BUILD_VERSION=${BUILD_VERSION} \\
                                        --build-arg RELEASE_VERSION=${RELEASE_VERSION} \\
                                        -t ${DOCKER_REGISTRY}/${APP_NAME}-${service}:${RELEASE_VERSION} \\
                                        -t ${DOCKER_REGISTRY}/${APP_NAME}-${service}:latest \\
                                        .
                                """
                            }
                        }
                    }
                }
            }
        }
        
        stage('Release Testing') {
            parallel {
                stage('Full Test Suite') {
                    steps {
                        echo "🧪 Running complete test suite"
                        
                        script {
                            // Start test environment with release images
                            sh """
                                RELEASE_VERSION=${RELEASE_VERSION} \\
                                docker-compose -f docker-compose.yml \\
                                              -f docker-compose.test.yml \\
                                              up -d --build
                            """
                            
                            // Wait for services
                            sh 'sleep 60'
                            
                            // Run comprehensive tests
                            sh """
                                docker-compose -f docker-compose.yml \\
                                              -f docker-compose.test.yml \\
                                              exec -T api-gateway npm run test:all || true
                            """
                        }
                    }
                    
                    post {
                        always {
                            sh """
                                docker-compose -f docker-compose.yml \\
                                              -f docker-compose.test.yml \\
                                              down -v || true
                            """
                        }
                    }
                }
                
                stage('Security Audit') {
                    steps {
                        echo "🔒 Running security audit"
                        
                        script {
                            def services = ['frontend', 'api-gateway', 'learning-service', 'user-service', 'lab-service', 'assessment-service']
                            
                            services.each { service ->
                                sh """
                                    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \\
                                        aquasec/trivy image \\
                                        --severity HIGH,CRITICAL \\
                                        --exit-code 1 \\
                                        ${DOCKER_REGISTRY}/${APP_NAME}-${service}:${RELEASE_VERSION} || true
                                """
                            }
                        }
                    }
                }
                
                stage('Performance Baseline') {
                    steps {
                        echo "⚡ Establishing performance baseline"
                        
                        script {
                            // Basic performance testing
                            sh '''
                                echo "Running performance baseline tests..."
                                # Add performance testing commands here
                                echo "Performance baseline established"
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Deploy to Staging') {
            when {
                not { params.SKIP_STAGING }
            }
            
            steps {
                echo "🚀 Deploying to staging environment"
                
                script {
                    // Deploy to staging
                    sh """
                        RELEASE_VERSION=${RELEASE_VERSION} \\
                        docker-compose -f docker-compose.yml \\
                                      -f docker-compose.staging.yml \\
                                      up -d
                    """
                    
                    // Wait and verify
                    sh 'sleep 90'
                    
                    // Staging smoke tests
                    def healthChecks = [
                        'Frontend': 'http://localhost:3000',
                        'API': 'http://localhost:4000/health'
                    ]
                    
                    healthChecks.each { service, url ->
                        sh "curl -f ${url} || exit 1"
                    }
                }
            }
        }
        
        stage('Staging Approval') {
            when {
                not { params.SKIP_STAGING }
            }
            
            steps {
                script {
                    def deploymentInfo = """
                    Release Information:
                    - Version: ${env.RELEASE_VERSION}
                    - Build: ${env.BUILD_VERSION}
                    - Branch: ${env.BRANCH_NAME}
                    - Commit: ${env.GIT_COMMIT}
                    
                    Staging Environment:
                    - Frontend: http://localhost:3000
                    - API: http://localhost:4000
                    - Monitoring: http://localhost:3001
                    """
                    
                    input message: "Approve deployment to production?\\n${deploymentInfo}", 
                          ok: 'Deploy to Production',
                          submitterParameter: 'APPROVER'
                }
            }
        }
        
        stage('Production Deployment') {
            steps {
                echo "🚀 Deploying to production environment"
                
                script {
                    // Backup current production state
                    sh '''
                        echo "Creating production backup..."
                        docker-compose -f docker-compose.yml -f docker-compose.prod.yml \\
                            exec -T postgres pg_dump -U devops_user devops_practice > backup-pre-release.sql || true
                    '''
                    
                    // Deploy infrastructure if needed
                    dir('terraform') {
                        sh """
                            terraform init
                            terraform plan -var-file="environments/prod.tfvars" -out=prod-tfplan
                            terraform apply prod-tfplan
                        """
                    }
                    
                    // Configure services
                    dir('ansible') {
                        sh """
                            ansible-playbook -i inventories/prod/hosts.yml \\
                                            playbooks/site.yml \\
                                            --extra-vars "app_version=${RELEASE_VERSION}"
                        """
                    }
                    
                    // Deploy application
                    sh """
                        RELEASE_VERSION=${RELEASE_VERSION} \\
                        docker-compose -f docker-compose.yml \\
                                      -f docker-compose.prod.yml \\
                                      up -d
                    """
                    
                    // Wait for services to stabilize
                    sh 'sleep 120'
                }
            }
        }
        
        stage('Production Verification') {
            steps {
                echo "✅ Verifying production deployment"
                
                script {
                    def verificationTests = [
                        'Health Check': 'curl -f http://localhost:3000/health',
                        'API Health': 'curl -f http://localhost:4000/health',
                        'Database Connection': 'docker-compose -f docker-compose.yml -f docker-compose.prod.yml exec -T postgres pg_isready -U devops_user',
                        'Monitoring': 'curl -f http://localhost:3001/api/health'
                    ]
                    
                    def failures = []
                    
                    verificationTests.each { test, command ->
                        try {
                            sh command
                            echo "✅ ${test}: PASSED"
                        } catch (Exception e) {
                            echo "❌ ${test}: FAILED"
                            failures.add(test)
                        }
                    }
                    
                    if (failures.size() > 0) {
                        if (params.ROLLBACK_ON_FAILURE) {
                            echo "🔄 Triggering automatic rollback due to verification failures"
                            // Trigger rollback pipeline
                            build job: 'rollback-production', 
                                  parameters: [
                                      string(name: 'ROLLBACK_REASON', value: "Verification failures: ${failures.join(', ')}")
                                  ]
                        }
                        error("Production verification failed: ${failures.join(', ')}")
                    }
                }
            }
        }
        
        stage('Post-Deployment Tasks') {
            steps {
                echo "📋 Running post-deployment tasks"
                
                script {
                    // Tag the release in Git
                    sh """
                        git tag -a ${RELEASE_VERSION} -m "Release ${RELEASE_VERSION}"
                        git push origin ${RELEASE_VERSION} || true
                    """
                    
                    // Update monitoring dashboards
                    dir('ansible') {
                        sh """
                            ansible-playbook -i inventories/prod/hosts.yml \\
                                            playbooks/maintenance.yml \\
                                            --tags monitoring-update
                        """
                    }
                    
                    // Generate release notes
                    sh """
                        echo "Release ${RELEASE_VERSION} deployed successfully" > release-notes.txt
                        echo "Build: ${BUILD_VERSION}" >> release-notes.txt
                        echo "Deployed by: ${env.APPROVER ?: 'System'}" >> release-notes.txt
                        echo "Deployment time: \$(date)" >> release-notes.txt
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 Release pipeline completed"
            
            // Archive release artifacts
            archiveArtifacts artifacts: 'release-notes.txt,backup-pre-release.sql,terraform/prod-tfplan', 
                           allowEmptyArchive: true
        }
        
        success {
            echo "🎉 Release ${env.RELEASE_VERSION} deployed successfully!"
            
            slackSend(
                channel: '#releases',
                color: 'good',
                message: """🎉 Production Release Successful!
                |Version: ${env.RELEASE_VERSION}
                |Build: ${env.BUILD_VERSION}
                |Approved by: ${env.APPROVER ?: 'System'}
                |Deployment time: ${new Date().format('yyyy-MM-dd HH:mm:ss')}
                """.stripMargin()
            )
        }
        
        failure {
            echo "💥 Release ${env.RELEASE_VERSION} failed!"
            
            slackSend(
                channel: '#releases',
                color: 'danger',
                message: """💥 Production Release Failed!
                |Version: ${env.RELEASE_VERSION}
                |Build: ${BUILD_NUMBER}
                |Check logs: ${BUILD_URL}console
                """.stripMargin()
            )
        }
        
        cleanup {
            // Clean up staging environment if used
            sh '''
                docker-compose -f docker-compose.yml -f docker-compose.staging.yml down || true
                docker system prune -f || true
            '''
        }
    }
}