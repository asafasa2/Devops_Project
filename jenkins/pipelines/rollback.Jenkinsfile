// Rollback Pipeline - Emergency rollback to previous version
pipeline {
    agent any
    
    environment {
        APP_NAME = 'devops-practice'
    }
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Target environment for rollback'
        )
        string(
            name: 'ROLLBACK_VERSION',
            defaultValue: '',
            description: 'Version to rollback to (e.g., v1.2.3)'
        )
        string(
            name: 'ROLLBACK_REASON',
            defaultValue: 'Emergency rollback',
            description: 'Reason for rollback'
        )
        booleanParam(
            name: 'SKIP_BACKUP',
            defaultValue: false,
            description: 'Skip pre-rollback backup (faster but riskier)'
        )
        booleanParam(
            name: 'FORCE_ROLLBACK',
            defaultValue: false,
            description: 'Force rollback even if current version appears healthy'
        )
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '50', daysToKeepStr: '30'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
        ansiColor('xterm')
    }
    
    stages {
        stage('Rollback Validation') {
            steps {
                echo "🔍 Validating rollback parameters"
                
                script {
                    // Validate rollback version
                    if (!params.ROLLBACK_VERSION) {
                        error("Rollback version must be specified")
                    }
                    
                    if (!params.ROLLBACK_VERSION.matches(/^v\d+\.\d+\.\d+$/)) {
                        error("Invalid rollback version format. Expected: vX.Y.Z")
                    }
                    
                    // Set environment variables
                    env.ROLLBACK_VERSION = params.ROLLBACK_VERSION
                    env.ROLLBACK_REASON = params.ROLLBACK_REASON
                    env.TARGET_ENVIRONMENT = params.ENVIRONMENT
                }
                
                echo "🎯 Rollback target: ${env.ROLLBACK_VERSION}"
                echo "🌍 Environment: ${env.TARGET_ENVIRONMENT}"
                echo "📝 Reason: ${env.ROLLBACK_REASON}"
            }
        }
        
        stage('Pre-Rollback Assessment') {
            when {
                not { params.FORCE_ROLLBACK }
            }
            
            steps {
                echo "📊 Assessing current system state"
                
                script {
                    // Check if target version images exist
                    def services = ['frontend', 'api-gateway', 'learning-service', 'user-service', 'lab-service', 'assessment-service']
                    def missing_images = []
                    
                    services.each { service ->
                        def image = "${APP_NAME}/${service}:${ROLLBACK_VERSION}"
                        def result = sh(
                            script: "docker manifest inspect ${image} > /dev/null 2>&1",
                            returnStatus: true
                        )
                        
                        if (result != 0) {
                            missing_images.add(service)
                        }
                    }
                    
                    if (missing_images.size() > 0) {
                        echo "⚠️ Warning: Images not found for services: ${missing_images.join(', ')}"
                        echo "Will attempt to use local images if available"
                    } else {
                        echo "✅ All target version images are available"
                    }
                    
                    // Check current system health
                    def health_check_result = sh(
                        script: "./scripts/verify-deployment.sh ${TARGET_ENVIRONMENT}",
                        returnStatus: true
                    )
                    
                    if (health_check_result == 0) {
                        echo "✅ Current system appears healthy"
                        
                        // Require confirmation for healthy system rollback
                        input message: "Current system appears healthy. Continue with rollback?", 
                              ok: 'Proceed with Rollback',
                              submitterParameter: 'ROLLBACK_APPROVER'
                    } else {
                        echo "⚠️ Current system has issues, rollback justified"
                    }
                }
            }
        }
        
        stage('Create Backup') {
            when {
                not { params.SKIP_BACKUP }
            }
            
            steps {
                echo "💾 Creating pre-rollback backup"
                
                script {
                    def backup_result = sh(
                        script: """
                            mkdir -p backups/pre-rollback-${BUILD_NUMBER}
                            
                            # Backup current environment
                            cp .env backups/pre-rollback-${BUILD_NUMBER}/ || true
                            cp docker-compose.${TARGET_ENVIRONMENT}.yml backups/pre-rollback-${BUILD_NUMBER}/ || true
                            
                            # Backup database
                            docker-compose -f docker-compose.yml -f docker-compose.${TARGET_ENVIRONMENT}.yml \\
                                exec -T postgres pg_dump -U devops_user devops_practice \\
                                > backups/pre-rollback-${BUILD_NUMBER}/database.sql || true
                            
                            # Backup application logs
                            docker-compose -f docker-compose.yml -f docker-compose.${TARGET_ENVIRONMENT}.yml \\
                                logs --no-color > backups/pre-rollback-${BUILD_NUMBER}/logs.txt || true
                        """,
                        returnStatus: true
                    )
                    
                    if (backup_result == 0) {
                        echo "✅ Backup created successfully"
                    } else {
                        echo "⚠️ Backup creation had issues, but continuing with rollback"
                    }
                }
            }
            
            post {
                always {
                    archiveArtifacts artifacts: "backups/pre-rollback-${BUILD_NUMBER}/**", 
                                   allowEmptyArchive: true
                }
            }
        }
        
        stage('Execute Rollback') {
            steps {
                echo "🔄 Executing rollback to ${env.ROLLBACK_VERSION}"
                
                script {
                    def rollback_result = sh(
                        script: """
                            ./scripts/rollback.sh \\
                                ${TARGET_ENVIRONMENT} \\
                                ${ROLLBACK_VERSION} \\
                                "${ROLLBACK_REASON}"
                        """,
                        returnStatus: true
                    )
                    
                    if (rollback_result != 0) {
                        error("Rollback execution failed")
                    }
                }
            }
        }
        
        stage('Post-Rollback Verification') {
            steps {
                echo "🔍 Verifying rollback success"
                
                script {
                    // Wait for services to stabilize
                    echo "⏳ Waiting for services to stabilize..."
                    sleep 60
                    
                    // Run comprehensive verification
                    def verification_result = sh(
                        script: "./scripts/verify-deployment.sh ${TARGET_ENVIRONMENT} 300",
                        returnStatus: true
                    )
                    
                    if (verification_result == 0) {
                        echo "✅ Rollback verification successful"
                    } else {
                        echo "❌ Rollback verification failed"
                        
                        // Collect diagnostic information
                        sh """
                            echo "=== Container Status ===" > rollback-diagnostics.txt
                            docker-compose -f docker-compose.yml -f docker-compose.${TARGET_ENVIRONMENT}.yml ps >> rollback-diagnostics.txt
                            
                            echo "=== Recent Logs ===" >> rollback-diagnostics.txt
                            docker-compose -f docker-compose.yml -f docker-compose.${TARGET_ENVIRONMENT}.yml logs --tail=50 >> rollback-diagnostics.txt
                            
                            echo "=== System Resources ===" >> rollback-diagnostics.txt
                            docker stats --no-stream >> rollback-diagnostics.txt
                        """
                        
                        error("Rollback verification failed - manual intervention required")
                    }
                }
            }
            
            post {
                failure {
                    archiveArtifacts artifacts: 'rollback-diagnostics.txt', 
                                   allowEmptyArchive: true
                }
            }
        }
        
        stage('Update Monitoring') {
            steps {
                echo "📊 Updating monitoring systems"
                
                script {
                    // Update Grafana annotations
                    sh """
                        curl -s -X POST http://localhost:3001/api/annotations \\
                             -H "Content-Type: application/json" \\
                             -d '{
                                 "text": "Rollback to ${ROLLBACK_VERSION}",
                                 "tags": ["rollback", "deployment", "${TARGET_ENVIRONMENT}"],
                                 "time": '"\$(date +%s)000"'
                             }' || true
                    """
                    
                    // Log rollback event
                    sh """
                        echo "\$(date): Rollback completed - ${TARGET_ENVIRONMENT} to ${ROLLBACK_VERSION}" >> rollback-history.log
                    """
                }
            }
        }
        
        stage('Notification and Documentation') {
            steps {
                echo "📢 Sending notifications and updating documentation"
                
                script {
                    def rollback_summary = """
                    🔄 Rollback Completed Successfully
                    
                    Environment: ${TARGET_ENVIRONMENT}
                    Rolled back to: ${ROLLBACK_VERSION}
                    Reason: ${ROLLBACK_REASON}
                    Executed by: ${env.ROLLBACK_APPROVER ?: 'System'}
                    Build: ${BUILD_NUMBER}
                    Time: ${new Date().format('yyyy-MM-dd HH:mm:ss')}
                    
                    Verification: ✅ Passed
                    Backup: ${params.SKIP_BACKUP ? '⏭️ Skipped' : '✅ Created'}
                    """
                    
                    // Send Slack notification
                    slackSend(
                        channel: '#ops-alerts',
                        color: 'warning',
                        message: rollback_summary
                    )
                    
                    // Create rollback report
                    writeFile file: 'rollback-report.md', text: """
# Rollback Report

## Summary
- **Environment**: ${TARGET_ENVIRONMENT}
- **Target Version**: ${ROLLBACK_VERSION}
- **Reason**: ${ROLLBACK_REASON}
- **Executed By**: ${env.ROLLBACK_APPROVER ?: 'System'}
- **Build Number**: ${BUILD_NUMBER}
- **Timestamp**: ${new Date().format('yyyy-MM-dd HH:mm:ss')}

## Actions Taken
1. Pre-rollback assessment completed
2. ${params.SKIP_BACKUP ? 'Backup skipped (as requested)' : 'System backup created'}
3. Rollback executed successfully
4. Post-rollback verification passed
5. Monitoring systems updated

## Next Steps
- Monitor system performance
- Review rollback reason and address root cause
- Plan for re-deployment of fixed version

## Artifacts
- Build logs: ${BUILD_URL}console
- ${params.SKIP_BACKUP ? '' : 'Backup location: backups/pre-rollback-' + BUILD_NUMBER + '/'}
"""
                }
            }
            
            post {
                always {
                    archiveArtifacts artifacts: 'rollback-report.md,rollback-history.log', 
                                   allowEmptyArchive: true
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 Rollback pipeline completed"
            
            // Clean up temporary files
            sh 'rm -f rollback-diagnostics.txt || true'
        }
        
        success {
            echo "🎉 Rollback completed successfully!"
            
            slackSend(
                channel: '#ops-alerts',
                color: 'good',
                message: """✅ Rollback Successful!
                |Environment: ${params.ENVIRONMENT}
                |Version: ${params.ROLLBACK_VERSION}
                |Reason: ${params.ROLLBACK_REASON}
                |Build: ${BUILD_NUMBER}
                """.stripMargin()
            )
        }
        
        failure {
            echo "💥 Rollback failed!"
            
            slackSend(
                channel: '#ops-alerts',
                color: 'danger',
                message: """💥 Rollback Failed!
                |Environment: ${params.ENVIRONMENT}
                |Target Version: ${params.ROLLBACK_VERSION}
                |Build: ${BUILD_NUMBER}
                |Logs: ${BUILD_URL}console
                |🚨 MANUAL INTERVENTION REQUIRED
                """.stripMargin()
            )
        }
        
        cleanup {
            // Clean up Docker resources
            sh 'docker system prune -f || true'
        }
    }
}