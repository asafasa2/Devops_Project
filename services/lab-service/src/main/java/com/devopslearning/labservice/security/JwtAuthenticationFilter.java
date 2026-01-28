package com.devopslearning.labservice.security;

import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.exceptions.JWTVerificationException;
import com.auth0.jwt.interfaces.DecodedJWT;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    
    @Value("${jwt.secret:default-jwt-secret}")
    private String jwtSecret;
    
    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        
        String authHeader = request.getHeader("Authorization");
        
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            
            try {
                Algorithm algorithm = Algorithm.HMAC256(jwtSecret);
                DecodedJWT decodedJWT = JWT.require(algorithm).build().verify(token);
                
                Long userId = decodedJWT.getClaim("sub").asLong();
                String username = decodedJWT.getClaim("username").asString();
                
                if (userId != null) {
                    JwtAuthenticationToken authToken = new JwtAuthenticationToken(
                            token, userId, username, Collections.emptyList());
                    SecurityContextHolder.getContext().setAuthentication(authToken);
                }
                
            } catch (JWTVerificationException e) {
                // Invalid token, continue without authentication
                logger.debug("Invalid JWT token: " + e.getMessage());
            }
        }
        
        filterChain.doFilter(request, response);
    }
    
    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        return path.equals("/labs/health") || path.startsWith("/actuator/");
    }
}