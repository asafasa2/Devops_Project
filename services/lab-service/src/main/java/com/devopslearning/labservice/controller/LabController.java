package com.devopslearning.labservice.controller;

import com.devopslearning.labservice.model.LabSession;
import com.devopslearning.labservice.service.LabService;
import com.devopslearning.labservice.security.JwtAuthenticationToken;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/labs")
@CrossOrigin(origins = "*")
public class LabController {
    
    @Autowired
    private LabService labService;
    
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        Map<String, Object> health = new HashMap<>();
        health.put("status", "healthy");
        health.put("timestamp", System.currentTimeMillis());
        health.put("service", "lab-service");
        return ResponseEntity.ok(health);
    }
    
    @GetMapping("/templates")
    public ResponseEntity<Map<String, Object>> getLabTemplates(Authentication authentication) {
        try {
            Map<String, Object> templates = labService.getLabTemplates();
            return ResponseEntity.ok(templates);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to retrieve lab templates: " + e.getMessage()));
        }
    }
    
    @PostMapping("/sessions")
    public ResponseEntity<Map<String, Object>> createLabSession(
            @RequestBody Map<String, Object> request,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);
            String labType = (String) request.get("lab_type");
            
            if (labType == null || labType.trim().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "Lab type is required"));
            }
            
            @SuppressWarnings("unchecked")
            Map<String, Object> labConfig = (Map<String, Object>) request.get("config");
            
            LabSession session = labService.createLabSession(userId, labType, labConfig);
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Lab session created successfully");
            response.put("session_id", session.getId());
            response.put("lab_type", session.getLabType());
            response.put("container_id", session.getContainerId());
            response.put("status", session.getStatus());
            response.put("start_time", session.getStartTime());
            
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
            
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage()));
        }
    }
    
    @GetMapping("/sessions")
    public ResponseEntity<Map<String, Object>> getUserLabSessions(
            @RequestParam(defaultValue = "false") boolean activeOnly,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);
            
            List<LabSession> sessions;
            if (activeOnly) {
                sessions = labService.getActiveUserLabSessions(userId);
            } else {
                sessions = labService.getUserLabSessions(userId);
            }
            
            Map<String, Object> response = new HashMap<>();
            response.put("sessions", sessions);
            response.put("total", sessions.size());
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to retrieve lab sessions: " + e.getMessage()));
        }
    }
    
    @GetMapping("/sessions/{sessionId}")
    public ResponseEntity<Map<String, Object>> getLabSession(
            @PathVariable Long sessionId,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);
            Optional<LabSession> sessionOpt = labService.getLabSession(sessionId, userId);
            
            if (sessionOpt.isEmpty()) {
                return ResponseEntity.notFound().build();
            }
            
            return ResponseEntity.ok(Map.of("session", sessionOpt.get()));
            
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to retrieve lab session: " + e.getMessage()));
        }
    }
    
    @GetMapping("/sessions/{sessionId}/status")
    public ResponseEntity<Map<String, Object>> getLabSessionStatus(
            @PathVariable Long sessionId,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);
            Map<String, Object> status = labService.getLabSessionStatus(sessionId, userId);
            
            return ResponseEntity.ok(status);
            
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage()));
        }
    }
    
    @DeleteMapping("/sessions/{sessionId}")
    public ResponseEntity<Map<String, Object>> terminateLabSession(
            @PathVariable Long sessionId,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);
            labService.terminateLabSession(sessionId, userId);
            
            return ResponseEntity.ok(Map.of("message", "Lab session terminated successfully"));
            
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage()));
        }
    }
    
    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getLabStatistics(Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);
            Map<String, Object> stats = labService.getLabStatistics(userId);
            
            return ResponseEntity.ok(stats);
            
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to retrieve lab statistics: " + e.getMessage()));
        }
    }
    
    private Long getUserIdFromAuth(Authentication authentication) {
        if (authentication instanceof JwtAuthenticationToken) {
            return ((JwtAuthenticationToken) authentication).getUserId();
        }
        throw new RuntimeException("Invalid authentication token");
    }
}