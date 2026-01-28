package com.devopslearning.labservice.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.Map;

@Entity
@Table(name = "lab_sessions")
public class LabSession {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @NotNull
    @Column(name = "user_id")
    private Long userId;
    
    @NotNull
    @Column(name = "lab_type", length = 50)
    private String labType;
    
    @Column(name = "container_id", length = 100)
    private String containerId;
    
    @Column(name = "status", length = 20)
    private String status = "active";
    
    @Column(name = "start_time")
    private LocalDateTime startTime = LocalDateTime.now();
    
    @Column(name = "end_time")
    private LocalDateTime endTime;
    
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "lab_data")
    private Map<String, Object> labData;
    
    // Constructors
    public LabSession() {}
    
    public LabSession(Long userId, String labType, String containerId, Map<String, Object> labData) {
        this.userId = userId;
        this.labType = labType;
        this.containerId = containerId;
        this.labData = labData;
    }
    
    // Getters and Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public Long getUserId() {
        return userId;
    }
    
    public void setUserId(Long userId) {
        this.userId = userId;
    }
    
    public String getLabType() {
        return labType;
    }
    
    public void setLabType(String labType) {
        this.labType = labType;
    }
    
    public String getContainerId() {
        return containerId;
    }
    
    public void setContainerId(String containerId) {
        this.containerId = containerId;
    }
    
    public String getStatus() {
        return status;
    }
    
    public void setStatus(String status) {
        this.status = status;
    }
    
    public LocalDateTime getStartTime() {
        return startTime;
    }
    
    public void setStartTime(LocalDateTime startTime) {
        this.startTime = startTime;
    }
    
    public LocalDateTime getEndTime() {
        return endTime;
    }
    
    public void setEndTime(LocalDateTime endTime) {
        this.endTime = endTime;
    }
    
    public Map<String, Object> getLabData() {
        return labData;
    }
    
    public void setLabData(Map<String, Object> labData) {
        this.labData = labData;
    }
}