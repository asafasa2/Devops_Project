#!/usr/bin/env groovy

import jenkins.model.*
import hudson.tools.*
import hudson.plugins.git.*
import jenkins.plugins.nodejs.tools.*
import org.jenkinsci.plugins.docker.commons.tools.*

def instance = Jenkins.getInstance()

// Configure Git
def gitInstallation = new GitTool("Default", "/usr/bin/git", [])
def gitDescriptor = instance.getDescriptor(GitTool.class)
gitDescriptor.setInstallations(gitInstallation)
gitDescriptor.save()

// Configure Docker
def dockerInstallation = new DockerTool("docker", "/usr/bin/docker", [])
def dockerDescriptor = instance.getDescriptor(DockerTool.class)
dockerDescriptor.setInstallations(dockerInstallation)
dockerDescriptor.save()

// Configure Node.js
def nodeInstallation = new NodeJSInstallation("NodeJS 18", "/usr/bin/node", [])
def nodeDescriptor = instance.getDescriptor(NodeJSInstallation.class)
nodeDescriptor.setInstallations(nodeInstallation)
nodeDescriptor.save()

instance.save()

println "Tools configuration completed"