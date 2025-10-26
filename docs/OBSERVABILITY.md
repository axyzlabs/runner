# Observability & Monitoring

This document describes the observability and monitoring features implemented in the GitHub Actions Runner Image.

## Overview

The runner image includes comprehensive observability features built on OpenTelemetry (OTEL), enabling real-time monitoring, health checks, and structured logging for production deployments.

## Components

### 1. OpenTelemetry Collector (v0.93.0)

The OTEL Collector aggregates and exports metrics for monitoring runner performance and health.

**Features:**
- Host metrics collection (CPU, memory, disk, network)
- Process metrics for resource tracking
- Prometheus-format metrics export
- Optional OTLP export to remote endpoints
- Built-in health check endpoint

**Configuration:** `/etc/otel/config.yaml`

**Metrics endpoint:** `http://localhost:8889/metrics`

**Health check:** `http://localhost:13133/health/collector`

### 2. Health Check System

Two health check endpoints provide runtime status information:

#### Liveness Check
Tests basic process health (container is running).

```bash
/usr/local/bin/health-check live
```

Returns:
```json
{
  "status": "healthy",
  "timestamp": "2025-10-26T12:00:00Z",
  "checks": {"process": "running"}
}
```

#### Readiness Check
Comprehensive health assessment of all critical components.

```bash
/usr/local/bin/health-check ready
```

Returns detailed status for:
- Claude Code CLI
- Go toolchain
- Python runtime
- Disk space availability
- MCP configuration
- OTEL Collector
- Memory usage
- Workspace accessibility

**Exit codes:**
- `0` = healthy
- `1` = unhealthy

### 3. Structured Logging

All logs can be output in JSON format for machine parsing and log aggregation systems.

**Log Wrapper Script:** `/usr/local/bin/log-wrapper`

**Usage:**
```bash
# Direct usage
log-wrapper INFO "Application started" component=api version=1.0.0

# Source in scripts
source /usr/local/bin/log-wrapper
log_info "Processing request" user_id=123 duration=45.2
log_error "Failed to connect" endpoint=api.example.com error_code=503
```

**Log Levels:**
- `DEBUG` - Detailed diagnostic information
- `INFO` - General informational messages
- `WARN` - Warning messages for non-critical issues
- `ERROR` - Error messages for failures
- `FATAL` - Critical errors that cause termination

**Output format:**
```json
{
  "timestamp": "2025-10-26T12:00:00.000Z",
  "level": "INFO",
  "message": "Application started",
  "context": {"component": "api", "version": "1.0.0"},
  "service": "github-actions-runner",
  "host": "container-id"
}
```

## Configuration

### Environment Variables

#### OTEL Configuration

- `ENABLE_OTEL` (default: `true`) - Enable/disable OTEL Collector
- `OTEL_ENDPOINT` - Remote OTLP endpoint for metrics export
- `OTEL_INSECURE` (default: `false`) - Use insecure connection (no TLS)
- `OTEL_CA_FILE` - Path to CA certificate for TLS
- `OTEL_CERT_FILE` - Path to client certificate
- `OTEL_KEY_FILE` - Path to client private key
- `OTEL_AUTH_HEADER` - Authorization header for OTLP endpoint
- `OTEL_LOG_LEVEL` (default: `info`) - OTEL Collector log level

#### Logging Configuration

- `LOG_LEVEL` (default: `INFO`) - Minimum log level to output
- `USE_JSON_LOGS` (default: `true`) - Enable structured JSON logging

#### Service Metadata

- `ENVIRONMENT` (default: `development`) - Deployment environment label
- `SERVICE_VERSION` (default: `1.0.0`) - Service version label

### Docker Compose Configuration

The observability features are fully integrated into `docker-compose.yml`:

```yaml
services:
  gha-runner:
    environment:
      - ENABLE_OTEL=true
      - OTEL_ENDPOINT=https://otel.example.com:4317
      - LOG_LEVEL=INFO
      - ENVIRONMENT=production
    ports:
      - "8889:8889"  # Prometheus metrics
    healthcheck:
      test: ["/usr/local/bin/health-check", "ready"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## Metrics Collected

### Host Metrics

- **CPU:**
  - `system.cpu.utilization` - Overall CPU usage percentage

- **Memory:**
  - `system.memory.usage` - Memory usage in bytes
  - `system.memory.utilization` - Memory usage percentage

- **Disk:**
  - `system.disk.io` - Disk I/O operations
  - `system.disk.operations` - Disk operation count
  - `system.filesystem.usage` - Filesystem usage in bytes
  - `system.filesystem.utilization` - Filesystem usage percentage

- **Network:**
  - `system.network.io` - Network I/O in bytes

- **Processes:**
  - `system.processes.count` - Total process count
  - `process.cpu.utilization` - Per-process CPU usage
  - `process.memory.usage` - Per-process memory usage

### Custom Labels

All metrics include:
- `service.name=github-actions-runner`
- `service.version` (from SERVICE_VERSION env var)
- `deployment.environment` (from ENVIRONMENT env var)
- `runner_type=github_actions`
- `claude_enabled=true`

## Usage Examples

### Accessing Metrics

#### From within container:
```bash
curl http://localhost:8889/metrics
```

#### From host (if port exposed):
```bash
curl http://localhost:8889/metrics
```

#### Filter specific metrics:
```bash
curl -s http://localhost:8889/metrics | grep runner_system_cpu
```

### Running Health Checks

#### Check container health:
```bash
docker exec zeeke-ai-runner /usr/local/bin/health-check ready
```

#### Automated health monitoring:
```bash
while true; do
  if docker exec zeeke-ai-runner /usr/local/bin/health-check ready; then
    echo "Container healthy"
  else
    echo "Container unhealthy!"
  fi
  sleep 30
done
```

### Viewing Structured Logs

#### Enable JSON logs:
```bash
docker run -e USE_JSON_LOGS=true zeeke-ai-runner:latest
```

#### Parse logs with jq:
```bash
docker logs zeeke-ai-runner | jq -r 'select(.level=="ERROR") | .message'
```

#### Filter by component:
```bash
docker logs zeeke-ai-runner | jq -r 'select(.context.component=="entrypoint")'
```

## Integration with Monitoring Systems

### Prometheus

Add to your `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'github-actions-runner'
    static_configs:
      - targets: ['localhost:8889']
        labels:
          environment: 'production'
          team: 'platform'
```

### Grafana

Sample dashboard queries:

**CPU Usage:**
```promql
rate(runner_system_cpu_utilization[5m])
```

**Memory Usage:**
```promql
runner_system_memory_usage / runner_system_memory_limit * 100
```

**Disk Usage:**
```promql
runner_system_filesystem_utilization{mountpoint="/"}
```

### OTLP Export

Configure remote OTLP endpoint:

```bash
docker run \
  -e OTEL_ENDPOINT=https://otel.example.com:4317 \
  -e OTEL_AUTH_HEADER="Bearer your-token" \
  zeeke-ai-runner:latest
```

### Log Aggregation (ELK, Splunk, etc.)

Configure Docker log driver:

```yaml
services:
  gha-runner:
    logging:
      driver: "fluentd"
      options:
        fluentd-address: "localhost:24224"
        tag: "github-actions-runner"
```

Or use JSON file driver with external collector:

```bash
docker logs zeeke-ai-runner -f | \
  filebeat -e -c /etc/filebeat/filebeat.yml
```

## Performance Impact

The observability stack is designed for minimal overhead:

- **CPU overhead:** < 2% (OTEL Collector)
- **Memory overhead:** ~50MB (OTEL Collector)
- **Logging overhead:** < 1% CPU (structured logging)
- **Total impact:** < 5% of container resources

**Measured performance:**
- Idle container: ~0.5% CPU, ~200MB memory
- Active workflow: ~5-15% CPU, ~1-2GB memory
- OTEL overhead: negligible in typical workloads

## Troubleshooting

### OTEL Collector not starting

**Check logs:**
```bash
docker exec zeeke-ai-runner cat /tmp/otelcol.log
```

**Verify configuration:**
```bash
docker exec zeeke-ai-runner cat /etc/otel/config.yaml
```

**Test manually:**
```bash
docker exec zeeke-ai-runner sudo otelcol --config=/etc/otel/config.yaml
```

### Metrics endpoint not responding

**Check if OTEL is enabled:**
```bash
docker exec zeeke-ai-runner bash -c 'echo $ENABLE_OTEL'
```

**Verify process is running:**
```bash
docker exec zeeke-ai-runner pgrep -f otelcol
```

**Check port binding:**
```bash
docker exec zeeke-ai-runner netstat -tlnp | grep 8889
```

### Health check failing

**Run manually with details:**
```bash
docker exec zeeke-ai-runner /usr/local/bin/health-check ready | jq '.'
```

**Check specific component:**
```bash
docker exec zeeke-ai-runner /usr/local/bin/health-check ready | \
  jq '.checks.claude_cli'
```

### High CPU usage

**Identify resource-intensive processes:**
```bash
docker exec zeeke-ai-runner ps aux --sort=-%cpu | head -10
```

**Check OTEL metrics:**
```bash
curl -s http://localhost:8889/metrics | grep process_cpu
```

### Logs not in JSON format

**Verify environment variable:**
```bash
docker exec zeeke-ai-runner bash -c 'echo $USE_JSON_LOGS'
```

**Test log wrapper directly:**
```bash
docker exec zeeke-ai-runner /usr/local/bin/log-wrapper INFO "Test"
```

## Security Considerations

### Metrics Endpoint Security

The Prometheus metrics endpoint (port 8889) exposes system metrics. In production:

1. **Don't expose publicly** - Use internal network or VPN
2. **Use authentication** - Place behind authenticated reverse proxy
3. **Filter sensitive data** - The OTEL config already filters secrets
4. **Limit access** - Use firewall rules or Docker network policies

Example with nginx reverse proxy:

```nginx
location /metrics {
    auth_basic "Metrics";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://runner:8889/metrics;
}
```

### OTLP Authentication

When sending metrics to remote OTLP endpoint:

1. **Use TLS** - Set `OTEL_INSECURE=false`
2. **Provide CA certificate** - Set `OTEL_CA_FILE`
3. **Use authentication** - Set `OTEL_AUTH_HEADER`
4. **Rotate credentials** - Update auth tokens regularly

### Log Security

Structured logs may contain sensitive information:

1. **Review log output** - Ensure no secrets in logs
2. **Use log filtering** - Remove sensitive fields before aggregation
3. **Secure log storage** - Encrypt logs at rest
4. **Limit access** - Restrict who can view logs

The log wrapper automatically escapes special characters but does not filter content.

## Best Practices

### 1. Set appropriate log levels

**Development:**
```yaml
environment:
  - LOG_LEVEL=DEBUG
  - OTEL_LOG_LEVEL=debug
```

**Production:**
```yaml
environment:
  - LOG_LEVEL=INFO
  - OTEL_LOG_LEVEL=info
```

### 2. Monitor key metrics

Set up alerts for:
- CPU usage > 80% for > 5 minutes
- Memory usage > 90%
- Disk usage > 85%
- Health check failures
- Error log rate increasing

### 3. Regular health checks

Configure orchestration system to use health checks:

**Kubernetes:**
```yaml
livenessProbe:
  exec:
    command: ["/usr/local/bin/health-check", "live"]
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  exec:
    command: ["/usr/local/bin/health-check", "ready"]
  initialDelaySeconds: 10
  periodSeconds: 5
```

**Docker Swarm:**
```yaml
healthcheck:
  test: ["/usr/local/bin/health-check", "ready"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 30s
```

### 4. Structured logging in scripts

Always use structured logging in custom scripts:

```bash
#!/bin/bash
source /usr/local/bin/log-wrapper

log_info "Script started" script_name="$0" user="$(whoami)"

if ! some_command; then
    log_error "Command failed" command="some_command" exit_code="$?"
    exit 1
fi

log_info "Script completed successfully" duration_seconds="$SECONDS"
```

### 5. Metric cardinality

Avoid high-cardinality labels in custom metrics:

**Good:**
```
runner_workflow_duration{status="success"}
```

**Bad:**
```
runner_workflow_duration{workflow_id="unique-id-12345"}
```

## Extending Observability

### Adding Custom Metrics

To add application-specific metrics, extend the OTEL configuration:

1. Create a metrics file in Prometheus format
2. Add file scraper to OTEL config
3. Restart container

Example:

```yaml
# In config/otel-collector-config.yaml
receivers:
  prometheus:
    config:
      scrape_configs:
        - job_name: 'custom-metrics'
          static_configs:
            - targets: ['localhost:9091']
```

### Custom Health Checks

Extend the health check script:

```bash
# Add to scripts/health-check.sh

# Check 9: Custom application
CHECKS="${CHECKS},"
if curl -sf http://localhost:3000/health &>/dev/null; then
    CHECKS="${CHECKS}\"custom_app\": {\"status\": \"healthy\"}"
else
    CHECKS="${CHECKS}\"custom_app\": {\"status\": \"unhealthy\"}"
    ALL_HEALTHY=false
fi
```

### Additional Exporters

Add exporters to OTEL config for other systems:

```yaml
exporters:
  datadog:
    api:
      key: ${DD_API_KEY}

  newrelic:
    apikey: ${NEW_RELIC_API_KEY}

service:
  pipelines:
    metrics:
      exporters: [prometheus, datadog, newrelic]
```

## References

- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Docker Logging](https://docs.docker.com/config/containers/logging/)
- [Health Check Best Practices](https://docs.docker.com/engine/reference/builder/#healthcheck)

## Support

For issues or questions about observability features:

1. Check this documentation
2. Review OTEL Collector logs: `/tmp/otelcol.log`
3. Test health checks manually
4. Open an issue on GitHub with:
   - Container logs
   - OTEL configuration
   - Health check output
   - Metrics sample
