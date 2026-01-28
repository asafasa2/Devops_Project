package com.devopslearning.labservice.repository;

import com.devopslearning.labservice.model.LabSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface LabSessionRepository extends JpaRepository<LabSession, Long> {
    
    List<LabSession> findByUserIdAndStatus(Long userId, String status);
    
    List<LabSession> findByUserId(Long userId);
    
    Optional<LabSession> findByContainerId(String containerId);
    
    List<LabSession> findByStatusAndStartTimeBefore(String status, LocalDateTime cutoffTime);
    
    @Query("SELECT COUNT(l) FROM LabSession l WHERE l.userId = :userId AND l.status = 'active'")
    long countActiveSessionsByUserId(@Param("userId") Long userId);
    
    @Query("SELECT l FROM LabSession l WHERE l.status = 'active' AND l.startTime < :cutoffTime")
    List<LabSession> findExpiredActiveSessions(@Param("cutoffTime") LocalDateTime cutoffTime);
}