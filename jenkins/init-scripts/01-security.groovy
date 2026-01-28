#!/usr/bin/env groovy

import jenkins.model.*
import hudson.security.*
import jenkins.security.s2m.AdminWhitelistRule

def instance = Jenkins.getInstance()

// Disable CLI over remoting
instance.getDescriptor("jenkins.CLI").get().setEnabled(false)

// Enable Agent to Master Access Control
instance.getInjector().getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)

// Disable usage statistics
instance.setNoUsageStatistics(true)

// Set number of executors
instance.setNumExecutors(2)

// Save configuration
instance.save()

println "Security configuration completed"