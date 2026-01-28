#!/bin/bash
# Setup script for Kibana index patterns and dashboards

KIBANA_URL="http://localhost:5601"
ELASTICSEARCH_URL="http://localhost:9200"

echo "Waiting for Kibana to be ready..."
until curl -s "$KIBANA_URL/api/status" | grep -q '"level":"available"'; do
  echo "Waiting for Kibana..."
  sleep 10
done

echo "Kibana is ready. Setting up index patterns..."

# Create index pattern for DevOps Practice logs
curl -X POST "$KIBANA_URL/api/saved_objects/index-pattern/devops-practice-logs-*" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" \
  -d '{
    "attributes": {
      "title": "devops-practice-logs-*",
      "timeFieldName": "@timestamp"
    }
  }'

echo "Index pattern created successfully."

# Set default index pattern
curl -X POST "$KIBANA_URL/api/kibana/settings/defaultIndex" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" \
  -d '{
    "value": "devops-practice-logs-*"
  }'

echo "Default index pattern set."

# Create a basic dashboard for log analysis
curl -X POST "$KIBANA_URL/api/saved_objects/dashboard/devops-practice-logs-dashboard" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" \
  -d '{
    "attributes": {
      "title": "DevOps Practice Logs Dashboard",
      "description": "Main dashboard for analyzing DevOps Practice Environment logs",
      "panelsJSON": "[]",
      "optionsJSON": "{\"useMargins\":true,\"syncColors\":false,\"hidePanelTitles\":false}",
      "version": 1,
      "timeRestore": false,
      "kibanaSavedObjectMeta": {
        "searchSourceJSON": "{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[]}"
      }
    }
  }'

echo "Dashboard created successfully."
echo "Kibana setup complete. Access Kibana at $KIBANA_URL"