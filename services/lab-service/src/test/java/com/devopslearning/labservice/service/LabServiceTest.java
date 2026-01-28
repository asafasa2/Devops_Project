package com.devopslearning.labservice.service;

import com.devopslearning.labservice.model.LabSession;
import com.devopslearning.labservice.repository.LabSessionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class LabServiceTest {

    @Mock
    private LabSessionRepository labSessionRepository;

    @Mock
    private DockerService dockerService;

    @InjectMocks
    private LabService labService;

    private Long userId;
    private String labType;
    private Map<String, Object> labConfig;
    private LabSession sampleLabSession;

    @BeforeEach
    void setUp() {
        userId = 1L;
        labType = "docker";
        labConfig = new HashMap<>();
        labConfig.put("memory", "512m");
        labConfig.put("cpu", "1");

        sampleLabSession = new LabSession();
        sampleLabSession.setId(1L);
        sampleLabSession.setUserId(userId);
        sampleLabSession.setLabType(labType);
        sampleLabSession.setContainerId("container123");
        sampleLabSession.setStatus("active");
        sampleLabSession.setStartTime(LocalDateTime.now());
        sampleLabSession.setLabData(labConfig);
    }

    @Test
    void createLabSession_Success() {
        // Arrange
        when(labSessionRepository.countActiveSessionsByUserId(userId)).thenReturn(2L);
        when(dockerService.createLabContainer(eq(labType), eq(userId), any())).thenReturn("container123");
        when(labSessionRepository.save(any(LabSession.class))).thenReturn(sampleLabSession);

        // Act
        LabSession result = labService.createLabSession(userId, labType, labConfig);

        // Assert
        assertNotNull(result);
        assertEquals(userId, result.getUserId());
        assertEquals(labType, result.getLabType());
        assertEquals("container123", result.getContainerId());
        assertEquals("active", result.getStatus());

        verify(labSessionRepository).countActiveSessionsByUserId(userId);
        verify(dockerService).createLabContainer(eq(labType), eq(userId), any());
        verify(labSessionRepository).save(any(LabSession.class));
    }

    @Test
    void createLabSession_MaxSessionsReached() {
        // Arrange
        when(labSessionRepository.countActiveSessionsByUserId(userId)).thenReturn(3L);

        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, () -> 
            labService.createLabSession(userId, labType, labConfig)
        );

        assertEquals("Maximum number of active lab sessions reached", exception.getMessage());
        verify(dockerService, never()).createLabContainer(any(), any(), any());
        verify(labSessionRepository, never()).save(any());
    }

    @Test
    void createLabSession_DockerServiceFailure() {
        // Arrange
        when(labSessionRepository.countActiveSessionsByUserId(userId)).thenReturn(1L);
        when(dockerService.createLabContainer(eq(labType), eq(userId), any()))
            .thenThrow(new RuntimeException("Docker container creation failed"));

        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, () -> 
            labService.createLabSession(userId, labType, labConfig)
        );

        assertTrue(exception.getMessage().contains("Failed to create lab session"));
        verify(labSessionRepository, never()).save(any());
    }

    @Test
    void terminateLabSession_Success() {
        // Arrange
        Long sessionId = 1L;
        when(labSessionRepository.findById(sessionId)).thenReturn(Optional.of(sampleLabSession));
        when(labSessionRepository.save(any(LabSession.class))).thenReturn(sampleLabSession);

        // Act
        labService.terminateLabSession(sessionId, userId);

        // Assert
        verify(dockerService).stopAndRemoveContainer("container123");
        verify(labSessionRepository).save(argThat(session -> 
            "terminated".equals(session.getStatus()) && session.getEndTime() != null
        ));
    }

    @Test
    void terminateLabSession_SessionNotFound() {
        // Arrange
        Long sessionId = 999L;
        when(labSessionRepository.findById(sessionId)).thenReturn(Optional.empty());

        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, () -> 
            labService.terminateLabSession(sessionId, userId)
        );

        assertEquals("Lab session not found", exception.getMessage());
        verify(dockerService, never()).stopAndRemoveContainer(any());
    }

    @Test
    void terminateLabSession_UnauthorizedUser() {
        // Arrange
        Long sessionId = 1L;
        Long unauthorizedUserId = 2L;
        when(labSessionRepository.findById(sessionId)).thenReturn(Optional.of(sampleLabSession));

        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, () -> 
            labService.terminateLabSession(sessionId, unauthorizedUserId)
        );

        assertEquals("Unauthorized to terminate this lab session", exception.getMessage());
        verify(dockerService, never()).stopAndRemoveContainer(any());
    }

    @Test
    void terminateLabSession_SessionNotActive() {
        // Arrange
        Long sessionId = 1L;
        sampleLabSession.setStatus("terminated");
        when(labSessionRepository.findById(sessionId)).thenReturn(Optional.of(sampleLabSession));

        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, () -> 
            labService.terminateLabSession(sessionId, userId)
        );

        assertEquals("Lab session is not active", exception.getMessage());
        verify(dockerService, never()).stopAndRemoveContainer(any());
    }

    @Test
    void getUserLabSessions_Success() {
        // Arrange
        List<LabSession> expectedSessions = Arrays.asList(sampleLabSession);
        when(labSessionRepository.findByUserId(userId)).thenReturn(expectedSessions);

        // Act
        List<LabSession> result = labService.getUserLabSessions(userId);

        // Assert
        assertEquals(expectedSessions, result);
        verify(labSessionRepository).findByUserId(userId);
    }

    @Test
    void getActiveUserLabSessions_Success() {
        // Arrange
        List<LabSession> expectedSessions = Arrays.asList(sampleLabSession);
        when(labSessionRepository.findByUserIdAndStatus(userId, "active")).thenReturn(expectedSessions);

        // Act
        List<LabSession> result = labService.getActiveUserLabSessions(userId);

        // Assert
        assertEquals(expectedSessions, result);
        verify(labSessionRepository).findByUserIdAndStatus(userId, "active");
    }

    @Test
    void getLabSession_Success() {
        // Arrange
        Long sessionId = 1L;
        when(labSessionRepository.findById(sessionId)).thenReturn(Optional.of(sampleLabSession));

        // Act
        Optional<LabSession> result = labService.getLabSession(sessionId, userId);

        // Assert
        assertTrue(result.isPresent());
        assertEquals(sampleLabSession, result.get());
    }

    @Test
    void getLabSession_UnauthorizedUser() {
        // Arrange
        Long sessionId = 1L;
        Long unauthorizedUserId = 2L;
        when(labSessionRepository.findById(sessionId)).thenReturn(Optional.of(sampleLabSession));

        // Act
        Optional<LabSession> result = labService.getLabSession(sessionId, unauthorizedUserId);

        // Assert
        assertFalse(result.isPresent());
    }

    @Test
    void getLabSessionStatus_Success() {
        // Arrange
        Long sessionId = 1L;
        when(labSessionRepository.findById(sessionId)).thenReturn(Optional.of(sampleLabSession));
        
        DockerService.ContainerStats containerStats = DockerService.ContainerStats.builder()
            .containerId("container123")
            .status("running")
            .running(true)
            .startedAt("2023-01-01T10:00:00Z")
            .build();
        
        when(dockerService.getContainerStats("container123")).thenReturn(containerStats);

        // Act
        Map<String, Object> result = labService.getLabSessionStatus(sessionId, userId);

        // Assert
        assertEquals(sessionId, result.get("session_id"));
        assertEquals(labType, result.get("lab_type"));
        assertEquals("active", result.get("status"));
        assertEquals("running", result.get("container_status"));
        assertEquals(true, result.get("container_running"));
        assertNotNull(result.get("start_time"));
    }

    @Test
    void getLabSessionStatus_SessionNotFound() {
        // Arrange
        Long sessionId = 999L;
        when(labSessionRepository.findById(sessionId)).thenReturn(Optional.empty());

        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, () -> 
            labService.getLabSessionStatus(sessionId, userId)
        );

        assertEquals("Lab session not found or unauthorized", exception.getMessage());
    }

    @Test
    void getLabSessionStatus_ContainerStatsFailure() {
        // Arrange
        Long sessionId = 1L;
        when(labSessionRepository.findById(sessionId)).thenReturn(Optional.of(sampleLabSession));
        when(dockerService.getContainerStats("container123"))
            .thenThrow(new RuntimeException("Container not found"));

        // Act
        Map<String, Object> result = labService.getLabSessionStatus(sessionId, userId);

        // Assert
        assertEquals("unknown", result.get("container_status"));
        assertEquals(false, result.get("container_running"));
    }

    @Test
    void getLabTemplates_Success() {
        // Act
        Map<String, Object> templates = labService.getLabTemplates();

        // Assert
        assertNotNull(templates);
        assertTrue(templates.containsKey("docker"));
        assertTrue(templates.containsKey("ansible"));
        assertTrue(templates.containsKey("terraform"));
        assertTrue(templates.containsKey("jenkins"));
        assertTrue(templates.containsKey("git"));

        // Verify Docker template structure
        @SuppressWarnings("unchecked")
        Map<String, Object> dockerTemplate = (Map<String, Object>) templates.get("docker");
        assertEquals("Docker Fundamentals", dockerTemplate.get("name"));
        assertEquals("beginner", dockerTemplate.get("difficulty"));
        assertEquals(120, dockerTemplate.get("estimated_duration"));
    }

    @Test
    void cleanupExpiredSessions_Success() {
        // Arrange
        LabSession expiredSession = new LabSession();
        expiredSession.setId(2L);
        expiredSession.setUserId(userId);
        expiredSession.setContainerId("expired-container");
        expiredSession.setStatus("active");
        
        List<LabSession> expiredSessions = Arrays.asList(expiredSession);
        when(labSessionRepository.findExpiredActiveSessions(any(LocalDateTime.class)))
            .thenReturn(expiredSessions);
        when(labSessionRepository.save(any(LabSession.class))).thenReturn(expiredSession);

        // Act
        labService.cleanupExpiredSessions();

        // Assert
        verify(dockerService).stopAndRemoveContainer("expired-container");
        verify(labSessionRepository).save(argThat(session -> 
            "expired".equals(session.getStatus()) && session.getEndTime() != null
        ));
    }

    @Test
    void cleanupExpiredSessions_DockerFailure() {
        // Arrange
        LabSession expiredSession = new LabSession();
        expiredSession.setId(2L);
        expiredSession.setContainerId("expired-container");
        expiredSession.setStatus("active");
        
        List<LabSession> expiredSessions = Arrays.asList(expiredSession);
        when(labSessionRepository.findExpiredActiveSessions(any(LocalDateTime.class)))
            .thenReturn(expiredSessions);
        doThrow(new RuntimeException("Docker cleanup failed"))
            .when(dockerService).stopAndRemoveContainer("expired-container");

        // Act (should not throw exception)
        assertDoesNotThrow(() -> labService.cleanupExpiredSessions());

        // Assert that the method continues despite Docker failure
        verify(dockerService).stopAndRemoveContainer("expired-container");
    }

    @Test
    void getLabStatistics_Success() {
        // Arrange
        LabSession session1 = new LabSession();
        session1.setLabType("docker");
        session1.setStatus("active");
        
        LabSession session2 = new LabSession();
        session2.setLabType("ansible");
        session2.setStatus("terminated");
        
        List<LabSession> allSessions = Arrays.asList(session1, session2);
        when(labSessionRepository.findByUserId(userId)).thenReturn(allSessions);
        when(labSessionRepository.countActiveSessionsByUserId(userId)).thenReturn(1L);

        // Act
        Map<String, Object> stats = labService.getLabStatistics(userId);

        // Assert
        assertEquals(2, stats.get("total_sessions"));
        assertEquals(1L, stats.get("active_sessions"));
        assertTrue(stats.containsKey("max_sessions_allowed"));
        
        @SuppressWarnings("unchecked")
        Map<String, Long> sessionsByType = (Map<String, Long>) stats.get("sessions_by_type");
        assertEquals(1L, sessionsByType.get("docker"));
        assertEquals(1L, sessionsByType.get("ansible"));
        
        @SuppressWarnings("unchecked")
        Map<String, Long> sessionsByStatus = (Map<String, Long>) stats.get("sessions_by_status");
        assertEquals(1L, sessionsByStatus.get("active"));
        assertEquals(1L, sessionsByStatus.get("terminated"));
    }
}