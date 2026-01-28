package com.devopslearning.labservice.service;

import com.github.dockerjava.api.DockerClient;
import com.github.dockerjava.api.command.CreateContainerResponse;
import com.github.dockerjava.api.model.*;
import com.github.dockerjava.core.DefaultDockerClientConfig;
import com.github.dockerjava.core.DockerClientBuilder;
import com.github.dockerjava.httpclient5.ApacheDockerHttpClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import java.time.Duration;
import java.util.*;

@Service
public class DockerService {
    
    private static final Logger logger = LoggerFactory.getLogger(DockerService.class);
    
    @Value("${docker.host:unix:///var/run/docker.sock}")
    private String dockerHost;
    
    @Value("${lab.network.name:lab-network}")
    private String labNetworkName;
    
    private DockerClient dockerClient;
    
    @PostConstruct
    public void init() {
        try {
            DefaultDockerClientConfig config = DefaultDockerClientConfig.createDefaultConfigBuilder()
                    .withDockerHost(dockerHost)
                    .build();
            
            ApacheDockerHttpClient httpClient = new ApacheDockerHttpClient.Builder()
                    .dockerHost(config.getDockerHost())
                    .sslConfig(config.getSSLConfig())
                    .maxConnections(100)
                    .connectionTimeout(Duration.ofSeconds(30))
                    .responseTimeout(Duration.ofSeconds(45))
                    .build();
            
            dockerClient = DockerClientBuilder.getInstance(config)
                    .withDockerHttpClient(httpClient)
                    .build();
            
            // Create lab network if it doesn't exist
            createLabNetwork();
            
            logger.info("Docker client initialized successfully");
        } catch (Exception e) {
            logger.error("Failed to initialize Docker client", e);
            throw new RuntimeException("Docker service initialization failed", e);
        }
    }
    
    @PreDestroy
    public void cleanup() {
        if (dockerClient != null) {
            try {
                dockerClient.close();
            } catch (Exception e) {
                logger.error("Error closing Docker client", e);
            }
        }
    }
    
    private void createLabNetwork() {
        try {
            // Check if network already exists
            List<Network> networks = dockerClient.listNetworksCmd()
                    .withNameFilter(labNetworkName)
                    .exec();
            
            if (networks.isEmpty()) {
                dockerClient.createNetworkCmd()
                        .withName(labNetworkName)
                        .withDriver("bridge")
                        .exec();
                logger.info("Created lab network: {}", labNetworkName);
            }
        } catch (Exception e) {
            logger.warn("Failed to create lab network", e);
        }
    }
    
    public String createLabContainer(String labType, Long userId, Map<String, Object> labConfig) {
        try {
            String imageName = getImageForLabType(labType);
            String containerName = generateContainerName(labType, userId);
            
            // Pull image if not exists
            pullImageIfNotExists(imageName);
            
            // Create container
            CreateContainerResponse container = dockerClient.createContainerCmd(imageName)
                    .withName(containerName)
                    .withHostConfig(HostConfig.newHostConfig()
                            .withMemory(512L * 1024 * 1024) // 512MB
                            .withCpuCount(1L)
                            .withAutoRemove(true)
                            .withNetworkMode(labNetworkName))
                    .withEnv(buildEnvironmentVariables(labConfig))
                    .withLabels(Map.of(
                            "lab.type", labType,
                            "lab.user", userId.toString(),
                            "lab.created", String.valueOf(System.currentTimeMillis())
                    ))
                    .exec();
            
            // Start container
            dockerClient.startContainerCmd(container.getId()).exec();
            
            logger.info("Created and started lab container: {} for user: {}", container.getId(), userId);
            return container.getId();
            
        } catch (Exception e) {
            logger.error("Failed to create lab container for type: {} and user: {}", labType, userId, e);
            throw new RuntimeException("Failed to create lab container", e);
        }
    }
    
    public void stopAndRemoveContainer(String containerId) {
        try {
            // Stop container
            dockerClient.stopContainerCmd(containerId)
                    .withTimeout(10)
                    .exec();
            
            // Remove container (auto-remove should handle this, but just in case)
            try {
                dockerClient.removeContainerCmd(containerId)
                        .withForce(true)
                        .exec();
            } catch (Exception e) {
                // Container might already be removed due to auto-remove
                logger.debug("Container might already be removed: {}", containerId);
            }
            
            logger.info("Stopped and removed container: {}", containerId);
            
        } catch (Exception e) {
            logger.error("Failed to stop/remove container: {}", containerId, e);
            throw new RuntimeException("Failed to stop container", e);
        }
    }
    
    public ContainerStats getContainerStats(String containerId) {
        try {
            InspectContainerResponse containerInfo = dockerClient.inspectContainerCmd(containerId).exec();
            
            return ContainerStats.builder()
                    .containerId(containerId)
                    .status(containerInfo.getState().getStatus())
                    .running(containerInfo.getState().getRunning())
                    .startedAt(containerInfo.getState().getStartedAt())
                    .build();
                    
        } catch (Exception e) {
            logger.error("Failed to get container stats for: {}", containerId, e);
            return ContainerStats.builder()
                    .containerId(containerId)
                    .status("unknown")
                    .running(false)
                    .build();
        }
    }
    
    public List<Container> listUserContainers(Long userId) {
        try {
            return dockerClient.listContainersCmd()
                    .withShowAll(true)
                    .withLabelFilter(Map.of("lab.user", userId.toString()))
                    .exec();
        } catch (Exception e) {
            logger.error("Failed to list containers for user: {}", userId, e);
            return Collections.emptyList();
        }
    }
    
    private String getImageForLabType(String labType) {
        return switch (labType.toLowerCase()) {
            case "docker" -> "docker:dind";
            case "ansible" -> "ansible/ansible-runner:latest";
            case "terraform" -> "hashicorp/terraform:latest";
            case "jenkins" -> "jenkins/jenkins:lts-alpine";
            case "git" -> "alpine/git:latest";
            case "ubuntu" -> "ubuntu:22.04";
            default -> "alpine:latest";
        };
    }
    
    private String generateContainerName(String labType, Long userId) {
        return String.format("lab-%s-%d-%d", labType, userId, System.currentTimeMillis());
    }
    
    private void pullImageIfNotExists(String imageName) {
        try {
            // Check if image exists locally
            dockerClient.inspectImageCmd(imageName).exec();
        } catch (Exception e) {
            // Image doesn't exist, pull it
            try {
                logger.info("Pulling image: {}", imageName);
                dockerClient.pullImageCmd(imageName).exec();
                logger.info("Successfully pulled image: {}", imageName);
            } catch (Exception pullException) {
                logger.error("Failed to pull image: {}", imageName, pullException);
                throw new RuntimeException("Failed to pull required image", pullException);
            }
        }
    }
    
    private List<String> buildEnvironmentVariables(Map<String, Object> labConfig) {
        List<String> envVars = new ArrayList<>();
        
        if (labConfig != null) {
            labConfig.forEach((key, value) -> {
                if (value != null) {
                    envVars.add(key + "=" + value.toString());
                }
            });
        }
        
        // Add default environment variables
        envVars.add("LAB_ENVIRONMENT=true");
        envVars.add("TERM=xterm");
        
        return envVars;
    }
    
    public static class ContainerStats {
        private String containerId;
        private String status;
        private Boolean running;
        private String startedAt;
        
        private ContainerStats(Builder builder) {
            this.containerId = builder.containerId;
            this.status = builder.status;
            this.running = builder.running;
            this.startedAt = builder.startedAt;
        }
        
        public static Builder builder() {
            return new Builder();
        }
        
        // Getters
        public String getContainerId() { return containerId; }
        public String getStatus() { return status; }
        public Boolean getRunning() { return running; }
        public String getStartedAt() { return startedAt; }
        
        public static class Builder {
            private String containerId;
            private String status;
            private Boolean running;
            private String startedAt;
            
            public Builder containerId(String containerId) {
                this.containerId = containerId;
                return this;
            }
            
            public Builder status(String status) {
                this.status = status;
                return this;
            }
            
            public Builder running(Boolean running) {
                this.running = running;
                return this;
            }
            
            public Builder startedAt(String startedAt) {
                this.startedAt = startedAt;
                return this;
            }
            
            public ContainerStats build() {
                return new ContainerStats(this);
            }
        }
    }
}