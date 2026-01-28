package com.devopslearning.labservice.service;

import com.devopslearning.labservice.model.LabSession;
import com.devopslearning.labservice.repository.LabSessionRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@Transactional
public class LabService {
    
    private static final Logger logger = LoggerFactory.getLogger(LabService.class);
    
    @Autowired
    private LabSessionRepository labSessionRepository;
    
    @Autowired
    private DockerService dockerService;
    
    @Value("${lab.max-sessions-per-user:3}")
    private int maxSessionsPerUser;
    
    @Value("${lab.session-timeout-hours:2}")
    private int sessionTimeoutHours;
    
    public LabSession createLabSession(Long userId, String labType, Map<String, Object> labConfig) {
        // Check if user has reached maximum active sessions
        long activeSessionsCount = labSessionRepository.countActiveSessionsByUserId(userId);
        if (activeSessionsCount >= maxSessionsPerUser) {
            throw new RuntimeException("Maximum number of active lab sessions reached");
        }
        
        try {
            // Create Docker container
            String containerId = dockerService.createLabContainer(labType, userId, labConfig);
            
            // Create lab session record
            Map<String, Object> sessionData = new HashMap<>(labConfig != null ? labConfig : new HashMap<>());
            sessionData.put("created_at", LocalDateTime.now().toString());
            sessionData.put("timeout_hours", sessionTimeoutHours);
            
            LabSession labSession = new LabSession(userId, labType, containerId, sessionData);
            labSession = labSessionRepository.save(labSession);
            
            logger.info("Created lab session {} for user {} with container {}", 
                       labSession.getId(), userId, containerId);
            
            return labSession;
            
        } catch (Exception e) {
            logger.error("Failed to create lab session for user {} and lab type {}", userId, labType, e);
            throw new RuntimeException("Failed to create lab session: " + e.getMessage());
        }
    }
    
    public void terminateLabSession(Long sessionId, Long userId) {
        Optional<LabSession> sessionOpt = labSessionRepository.findById(sessionId);
        
        if (sessionOpt.isEmpty()) {
            throw new RuntimeException("Lab session not found");
        }
        
        LabSession session = sessionOpt.get();
        
        // Verify ownership
        if (!session.getUserId().equals(userId)) {
            throw new RuntimeException("Unauthorized to terminate this lab session");
        }
        
        if (!"active".equals(session.getStatus())) {
            throw new RuntimeException("Lab session is not active");
        }
        
        try {
            // Stop and remove Docker container
            if (session.getContainerId() != null) {
                dockerService.stopAndRemoveContainer(session.getContainerId());
            }
            
            // Update session status
            session.setStatus("terminated");
            session.setEndTime(LocalDateTime.now());
            labSessionRepository.save(session);
            
            logger.info("Terminated lab session {} for user {}", sessionId, userId);
            
        } catch (Exception e) {
            logger.error("Failed to terminate lab session {} for user {}", sessionId, userId, e);
            throw new RuntimeException("Failed to terminate lab session: " + e.getMessage());
        }
    }
    
    public List<LabSession> getUserLabSessions(Long userId) {
        return labSessionRepository.findByUserId(userId);
    }
    
    public List<LabSession> getActiveUserLabSessions(Long userId) {
        return labSessionRepository.findByUserIdAndStatus(userId, "active");
    }
    
    public Optional<LabSession> getLabSession(Long sessionId, Long userId) {
        Optional<LabSession> sessionOpt = labSessionRepository.findById(sessionId);
        
        if (sessionOpt.isPresent() && sessionOpt.get().getUserId().equals(userId)) {
            return sessionOpt;
        }
        
        return Optional.empty();
    }
    
    public Map<String, Object> getLabSessionStatus(Long sessionId, Long userId) {
        Optional<LabSession> sessionOpt = getLabSession(sessionId, userId);
        
        if (sessionOpt.isEmpty()) {
            throw new RuntimeException("Lab session not found or unauthorized");
        }
        
        LabSession session = sessionOpt.get();
        Map<String, Object> status = new HashMap<>();
        
        status.put("session_id", session.getId());
        status.put("lab_type", session.getLabType());
        status.put("status", session.getStatus());
        status.put("start_time", session.getStartTime());
        status.put("end_time", session.getEndTime());
        
        // Get container status if active
        if ("active".equals(session.getStatus()) && session.getContainerId() != null) {
            try {
                DockerService.ContainerStats containerStats = dockerService.getContainerStats(session.getContainerId());
                status.put("container_status", containerStats.getStatus());
                status.put("container_running", containerStats.getRunning());
                status.put("container_started_at", containerStats.getStartedAt());
            } catch (Exception e) {
                logger.warn("Failed to get container status for session {}", sessionId, e);
                status.put("container_status", "unknown");
                status.put("container_running", false);
            }
        }
        
        return status;
    }
    
    public Map<String, Object> getLabTemplates() {
        Map<String, Object> templates = new HashMap<>();
        
        // Docker lab template
        Map<String, Object> dockerTemplate = new HashMap<>();
        dockerTemplate.put("name", "Docker Fundamentals");
        dockerTemplate.put("description", "Learn Docker basics with hands-on exercises");
        dockerTemplate.put("estimated_duration", 120); // minutes
        dockerTemplate.put("difficulty", "beginner");
        dockerTemplate.put("tools", List.of("docker", "docker-compose"));
        templates.put("docker", dockerTemplate);
        
        // Ansible lab template
        Map<String, Object> ansibleTemplate = new HashMap<>();
        ansibleTemplate.put("name", "Ansible Configuration Management");
        ansibleTemplate.put("description", "Practice Ansible playbooks and automation");
        ansibleTemplate.put("estimated_duration", 90);
        ansibleTemplate.put("difficulty", "intermediate");
        ansibleTemplate.put("tools", List.of("ansible", "ansible-playbook"));
        templates.put("ansible", ansibleTemplate);
        
        // Terraform lab template
        Map<String, Object> terraformTemplate = new HashMap<>();
        terraformTemplate.put("name", "Infrastructure as Code with Terraform");
        terraformTemplate.put("description", "Learn Terraform for infrastructure provisioning");
        terraformTemplate.put("estimated_duration", 150);
        terraformTemplate.put("difficulty", "intermediate");
        terraformTemplate.put("tools", List.of("terraform", "terraform-plan"));
        templates.put("terraform", terraformTemplate);
        
        // Jenkins lab template
        Map<String, Object> jenkinsTemplate = new HashMap<>();
        jenkinsTemplate.put("name", "CI/CD with Jenkins");
        jenkinsTemplate.put("description", "Build and deploy applications with Jenkins pipelines");
        jenkinsTemplate.put("estimated_duration", 180);
        jenkinsTemplate.put("difficulty", "advanced");
        jenkinsTemplate.put("tools", List.of("jenkins", "pipeline", "groovy"));
        templates.put("jenkins", jenkinsTemplate);
        
        // Git lab template
        Map<String, Object> gitTemplate = new HashMap<>();
        gitTemplate.put("name", "Git Version Control");
        gitTemplate.put("description", "Master Git workflows and collaboration");
        gitTemplate.put("estimated_duration", 60);
        gitTemplate.put("difficulty", "beginner");
        gitTemplate.put("tools", List.of("git", "github"));
        templates.put("git", gitTemplate);
        
        return templates;
    }
    
    // Scheduled cleanup of expired sessions
    @Scheduled(fixedRate = 300000) // Run every 5 minutes
    public void cleanupExpiredSessions() {
        LocalDateTime cutoffTime = LocalDateTime.now().minusHours(sessionTimeoutHours);
        List<LabSession> expiredSessions = labSessionRepository.findExpiredActiveSessions(cutoffTime);
        
        for (LabSession session : expiredSessions) {
            try {
                logger.info("Cleaning up expired session: {}", session.getId());
                
                // Stop and remove container
                if (session.getContainerId() != null) {
                    dockerService.stopAndRemoveContainer(session.getContainerId());
                }
                
                // Update session status
                session.setStatus("expired");
                session.setEndTime(LocalDateTime.now());
                labSessionRepository.save(session);
                
            } catch (Exception e) {
                logger.error("Failed to cleanup expired session: {}", session.getId(), e);
            }
        }
        
        if (!expiredSessions.isEmpty()) {
            logger.info("Cleaned up {} expired lab sessions", expiredSessions.size());
        }
    }
    
    public Map<String, Object> getLabStatistics(Long userId) {
        List<LabSession> allSessions = labSessionRepository.findByUserId(userId);
        long activeSessions = labSessionRepository.countActiveSessionsByUserId(userId);
        
        Map<String, Long> sessionsByType = new HashMap<>();
        Map<String, Long> sessionsByStatus = new HashMap<>();
        
        for (LabSession session : allSessions) {
            sessionsByType.merge(session.getLabType(), 1L, Long::sum);
            sessionsByStatus.merge(session.getStatus(), 1L, Long::sum);
        }
        
        Map<String, Object> stats = new HashMap<>();
        stats.put("total_sessions", allSessions.size());
        stats.put("active_sessions", activeSessions);
        stats.put("max_sessions_allowed", maxSessionsPerUser);
        stats.put("sessions_by_type", sessionsByType);
        stats.put("sessions_by_status", sessionsByStatus);
        
        return stats;
    }
}