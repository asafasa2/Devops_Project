package com.devopslearning.labservice.service;

import com.github.dockerjava.api.DockerClient;
import com.github.dockerjava.api.command.*;
import com.github.dockerjava.api.model.Container;
import com.github.dockerjava.api.model.ContainerState;
import com.github.dockerjava.api.model.Network;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DockerServiceTest {

    @Mock
    private DockerClient dockerClient;

    @Mock
    private CreateContainerCmd createContainerCmd;

    @Mock
    private StartContainerCmd startContainerCmd;

    @Mock
    private StopContainerCmd stopContainerCmd;

    @Mock
    private RemoveContainerCmd removeContainerCmd;

    @Mock
    private InspectContainerCmd inspectContainerCmd;

    @Mock
    private ListContainersCmd listContainersCmd;

    @Mock
    private ListNetworksCmd listNetworksCmd;

    @Mock
    private CreateNetworkCmd createNetworkCmd;

    @Mock
    private PullImageCmd pullImageCmd;

    @Mock
    private InspectImageCmd inspectImageCmd;

    @InjectMocks
    private DockerService dockerService;

    private Long userId;
    private String labType;
    private Map<String, Object> labConfig;

    @BeforeEach
    void setUp() {
        userId = 1L;
        labType = "docker";
        labConfig = new HashMap<>();
        labConfig.put("memory", "512m");
        labConfig.put("cpu", "1");

        // Set private fields using reflection
        ReflectionTestUtils.setField(dockerService, "dockerClient", dockerClient);
        ReflectionTestUtils.setField(dockerService, "labNetworkName", "lab-network");
    }

    @Test
    void createLabContainer_Success() {
        // Arrange
        String expectedContainerId = "container123";
        CreateContainerResponse createResponse = mock(CreateContainerResponse.class);
        when(createResponse.getId()).thenReturn(expectedContainerId);

        when(dockerClient.inspectImageCmd(anyString())).thenReturn(inspectImageCmd);
        when(inspectImageCmd.exec()).thenReturn(null); // Image exists

        when(dockerClient.createContainerCmd(anyString())).thenReturn(createContainerCmd);
        when(createContainerCmd.withName(anyString())).thenReturn(createContainerCmd);
        when(createContainerCmd.withHostConfig(any())).thenReturn(createContainerCmd);
        when(createContainerCmd.withEnv(any())).thenReturn(createContainerCmd);
        when(createContainerCmd.withLabels(any())).thenReturn(createContainerCmd);
        when(createContainerCmd.exec()).thenReturn(createResponse);

        when(dockerClient.startContainerCmd(expectedContainerId)).thenReturn(startContainerCmd);
        when(startContainerCmd.exec()).thenReturn(null);

        // Act
        String result = dockerService.createLabContainer(labType, userId, labConfig);

        // Assert
        assertEquals(expectedContainerId, result);
        verify(dockerClient).createContainerCmd("docker:dind");
        verify(dockerClient).startContainerCmd(expectedContainerId);
        verify(createContainerCmd).withName(contains("lab-docker-1"));
        verify(createContainerCmd).withEnv(argThat(envVars -> 
            envVars.contains("LAB_ENVIRONMENT=true") && 
            envVars.contains("memory=512m")
        ));
    }

    @Test
    void createLabContainer_ImageNotExists_PullsImage() {
        // Arrange
        String expectedContainerId = "container123";
        CreateContainerResponse createResponse = mock(CreateContainerResponse.class);
        when(createResponse.getId()).thenReturn(expectedContainerId);

        // First call fails (image doesn't exist), second call succeeds after pull
        when(dockerClient.inspectImageCmd(anyString())).thenReturn(inspectImageCmd);
        when(inspectImageCmd.exec())
            .thenThrow(new RuntimeException("Image not found"))
            .thenReturn(null);

        when(dockerClient.pullImageCmd(anyString())).thenReturn(pullImageCmd);
        when(pullImageCmd.exec()).thenReturn(null);

        when(dockerClient.createContainerCmd(anyString())).thenReturn(createContainerCmd);
        when(createContainerCmd.withName(anyString())).thenReturn(createContainerCmd);
        when(createContainerCmd.withHostConfig(any())).thenReturn(createContainerCmd);
        when(createContainerCmd.withEnv(any())).thenReturn(createContainerCmd);
        when(createContainerCmd.withLabels(any())).thenReturn(createContainerCmd);
        when(createContainerCmd.exec()).thenReturn(createResponse);

        when(dockerClient.startContainerCmd(expectedContainerId)).thenReturn(startContainerCmd);
        when(startContainerCmd.exec()).thenReturn(null);

        // Act
        String result = dockerService.createLabContainer(labType, userId, labConfig);

        // Assert
        assertEquals(expectedContainerId, result);
        verify(dockerClient).pullImageCmd("docker:dind");
        verify(pullImageCmd).exec();
    }

    @Test
    void createLabContainer_PullImageFails() {
        // Arrange
        when(dockerClient.inspectImageCmd(anyString())).thenReturn(inspectImageCmd);
        when(inspectImageCmd.exec()).thenThrow(new RuntimeException("Image not found"));

        when(dockerClient.pullImageCmd(anyString())).thenReturn(pullImageCmd);
        when(pullImageCmd.exec()).thenThrow(new RuntimeException("Pull failed"));

        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, () -> 
            dockerService.createLabContainer(labType, userId, labConfig)
        );

        assertTrue(exception.getMessage().contains("Failed to create lab container"));
        verify(dockerClient, never()).createContainerCmd(anyString());
    }

    @Test
    void createLabContainer_CreateContainerFails() {
        // Arrange
        when(dockerClient.inspectImageCmd(anyString())).thenReturn(inspectImageCmd);
        when(inspectImageCmd.exec()).thenReturn(null);

        when(dockerClient.createContainerCmd(anyString())).thenReturn(createContainerCmd);
        when(createContainerCmd.withName(anyString())).thenReturn(createContainerCmd);
        when(createContainerCmd.withHostConfig(any())).thenReturn(createContainerCmd);
        when(createContainerCmd.withEnv(any())).thenReturn(createContainerCmd);
        when(createContainerCmd.withLabels(any())).thenReturn(createContainerCmd);
        when(createContainerCmd.exec()).thenThrow(new RuntimeException("Container creation failed"));

        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, () -> 
            dockerService.createLabContainer(labType, userId, labConfig)
        );

        assertTrue(exception.getMessage().contains("Failed to create lab container"));
    }

    @Test
    void stopAndRemoveContainer_Success() {
        // Arrange
        String containerId = "container123";
        when(dockerClient.stopContainerCmd(containerId)).thenReturn(stopContainerCmd);
        when(stopContainerCmd.withTimeout(10)).thenReturn(stopContainerCmd);
        when(stopContainerCmd.exec()).thenReturn(null);

        when(dockerClient.removeContainerCmd(containerId)).thenReturn(removeContainerCmd);
        when(removeContainerCmd.withForce(true)).thenReturn(removeContainerCmd);
        when(removeContainerCmd.exec()).thenReturn(null);

        // Act
        assertDoesNotThrow(() -> dockerService.stopAndRemoveContainer(containerId));

        // Assert
        verify(dockerClient).stopContainerCmd(containerId);
        verify(stopContainerCmd).withTimeout(10);
        verify(dockerClient).removeContainerCmd(containerId);
        verify(removeContainerCmd).withForce(true);
    }

    @Test
    void stopAndRemoveContainer_StopFails() {
        // Arrange
        String containerId = "container123";
        when(dockerClient.stopContainerCmd(containerId)).thenReturn(stopContainerCmd);
        when(stopContainerCmd.withTimeout(10)).thenReturn(stopContainerCmd);
        when(stopContainerCmd.exec()).thenThrow(new RuntimeException("Stop failed"));

        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, () -> 
            dockerService.stopAndRemoveContainer(containerId)
        );

        assertTrue(exception.getMessage().contains("Failed to stop container"));
        verify(dockerClient, never()).removeContainerCmd(anyString());
    }

    @Test
    void stopAndRemoveContainer_RemoveFailsButContinues() {
        // Arrange
        String containerId = "container123";
        when(dockerClient.stopContainerCmd(containerId)).thenReturn(stopContainerCmd);
        when(stopContainerCmd.withTimeout(10)).thenReturn(stopContainerCmd);
        when(stopContainerCmd.exec()).thenReturn(null);

        when(dockerClient.removeContainerCmd(containerId)).thenReturn(removeContainerCmd);
        when(removeContainerCmd.withForce(true)).thenReturn(removeContainerCmd);
        when(removeContainerCmd.exec()).thenThrow(new RuntimeException("Container already removed"));

        // Act (should not throw exception due to auto-remove handling)
        assertDoesNotThrow(() -> dockerService.stopAndRemoveContainer(containerId));

        // Assert
        verify(dockerClient).stopContainerCmd(containerId);
        verify(dockerClient).removeContainerCmd(containerId);
    }

    @Test
    void getContainerStats_Success() {
        // Arrange
        String containerId = "container123";
        InspectContainerResponse containerInfo = mock(InspectContainerResponse.class);
        ContainerState containerState = mock(ContainerState.class);

        when(dockerClient.inspectContainerCmd(containerId)).thenReturn(inspectContainerCmd);
        when(inspectContainerCmd.exec()).thenReturn(containerInfo);
        when(containerInfo.getState()).thenReturn(containerState);
        when(containerState.getStatus()).thenReturn("running");
        when(containerState.getRunning()).thenReturn(true);
        when(containerState.getStartedAt()).thenReturn("2023-01-01T10:00:00Z");

        // Act
        DockerService.ContainerStats result = dockerService.getContainerStats(containerId);

        // Assert
        assertEquals(containerId, result.getContainerId());
        assertEquals("running", result.getStatus());
        assertEquals(true, result.getRunning());
        assertEquals("2023-01-01T10:00:00Z", result.getStartedAt());
    }

    @Test
    void getContainerStats_ContainerNotFound() {
        // Arrange
        String containerId = "nonexistent";
        when(dockerClient.inspectContainerCmd(containerId)).thenReturn(inspectContainerCmd);
        when(inspectContainerCmd.exec()).thenThrow(new RuntimeException("Container not found"));

        // Act
        DockerService.ContainerStats result = dockerService.getContainerStats(containerId);

        // Assert
        assertEquals(containerId, result.getContainerId());
        assertEquals("unknown", result.getStatus());
        assertEquals(false, result.getRunning());
        assertNull(result.getStartedAt());
    }

    @Test
    void listUserContainers_Success() {
        // Arrange
        Container container1 = mock(Container.class);
        Container container2 = mock(Container.class);
        List<Container> expectedContainers = Arrays.asList(container1, container2);

        when(dockerClient.listContainersCmd()).thenReturn(listContainersCmd);
        when(listContainersCmd.withShowAll(true)).thenReturn(listContainersCmd);
        when(listContainersCmd.withLabelFilter(any())).thenReturn(listContainersCmd);
        when(listContainersCmd.exec()).thenReturn(expectedContainers);

        // Act
        List<Container> result = dockerService.listUserContainers(userId);

        // Assert
        assertEquals(expectedContainers, result);
        verify(listContainersCmd).withLabelFilter(Map.of("lab.user", userId.toString()));
    }

    @Test
    void listUserContainers_DockerClientFails() {
        // Arrange
        when(dockerClient.listContainersCmd()).thenReturn(listContainersCmd);
        when(listContainersCmd.withShowAll(true)).thenReturn(listContainersCmd);
        when(listContainersCmd.withLabelFilter(any())).thenReturn(listContainersCmd);
        when(listContainersCmd.exec()).thenThrow(new RuntimeException("Docker client error"));

        // Act
        List<Container> result = dockerService.listUserContainers(userId);

        // Assert
        assertTrue(result.isEmpty());
    }

    @Test
    void getImageForLabType_ReturnsCorrectImages() {
        // Test different lab types return correct Docker images
        assertEquals("docker:dind", ReflectionTestUtils.invokeMethod(dockerService, "getImageForLabType", "docker"));
        assertEquals("ansible/ansible-runner:latest", ReflectionTestUtils.invokeMethod(dockerService, "getImageForLabType", "ansible"));
        assertEquals("hashicorp/terraform:latest", ReflectionTestUtils.invokeMethod(dockerService, "getImageForLabType", "terraform"));
        assertEquals("jenkins/jenkins:lts-alpine", ReflectionTestUtils.invokeMethod(dockerService, "getImageForLabType", "jenkins"));
        assertEquals("alpine/git:latest", ReflectionTestUtils.invokeMethod(dockerService, "getImageForLabType", "git"));
        assertEquals("ubuntu:22.04", ReflectionTestUtils.invokeMethod(dockerService, "getImageForLabType", "ubuntu"));
        assertEquals("alpine:latest", ReflectionTestUtils.invokeMethod(dockerService, "getImageForLabType", "unknown"));
    }

    @Test
    void generateContainerName_CreatesValidName() {
        // Act
        String result = ReflectionTestUtils.invokeMethod(dockerService, "generateContainerName", labType, userId);

        // Assert
        assertNotNull(result);
        assertTrue(result.startsWith("lab-docker-1-"));
        assertTrue(result.length() > "lab-docker-1-".length());
    }

    @Test
    void buildEnvironmentVariables_IncludesConfigAndDefaults() {
        // Act
        @SuppressWarnings("unchecked")
        List<String> result = (List<String>) ReflectionTestUtils.invokeMethod(
            dockerService, "buildEnvironmentVariables", labConfig
        );

        // Assert
        assertNotNull(result);
        assertTrue(result.contains("memory=512m"));
        assertTrue(result.contains("cpu=1"));
        assertTrue(result.contains("LAB_ENVIRONMENT=true"));
        assertTrue(result.contains("TERM=xterm"));
    }

    @Test
    void buildEnvironmentVariables_HandlesNullConfig() {
        // Act
        @SuppressWarnings("unchecked")
        List<String> result = (List<String>) ReflectionTestUtils.invokeMethod(
            dockerService, "buildEnvironmentVariables", (Map<String, Object>) null
        );

        // Assert
        assertNotNull(result);
        assertTrue(result.contains("LAB_ENVIRONMENT=true"));
        assertTrue(result.contains("TERM=xterm"));
        assertEquals(2, result.size()); // Only default variables
    }

    @Test
    void containerStatsBuilder_WorksCorrectly() {
        // Act
        DockerService.ContainerStats stats = DockerService.ContainerStats.builder()
            .containerId("test123")
            .status("running")
            .running(true)
            .startedAt("2023-01-01T10:00:00Z")
            .build();

        // Assert
        assertEquals("test123", stats.getContainerId());
        assertEquals("running", stats.getStatus());
        assertEquals(true, stats.getRunning());
        assertEquals("2023-01-01T10:00:00Z", stats.getStartedAt());
    }
}