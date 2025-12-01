# Usage Guide

## Quick Reference

### Basic Example

```yaml
- name: Run Load Test
  uses: your-org/postman-to-k6-action@v1
  with:
    postman-collection: 'postman/collection.json'
    load-profile: 'smoke'
```

### Advanced Example with Multiple Profiles

```yaml
jobs:
  load-test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        profile: [smoke, load, stress, spike]
    steps:
      - uses: actions/checkout@v4
      - uses: your-org/postman-to-k6-action@v1
        with:
          postman-collection: 'postman/collection.json'
          load-profile: ${{ matrix.profile }}
```

## Input Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `postman-collection` | string | Yes | Path to Postman collection JSON file |
| `load-profile` | string | No | Load profile: `smoke`, `load`, `stress`, or `spike` (default: `smoke`) |
| `environment-file` | string | No | Path to Postman environment file |
| `profiles-config` | string | No | Path to custom profiles YAML (default: `profiles/load-profiles.yaml`) |
| `k6-options` | string | No | Additional k6 CLI flags |
| `node-version` | string | No | Node.js version for conversion (default: `18`) |

## Load Profiles Explained

### Smoke Test
- **Use case**: Quick validation
- **Duration**: ~1 minute
- **Load**: 5 virtual users
- **Best for**: CI/CD pipeline checks

### Load Test
- **Use case**: Normal expected load
- **Duration**: ~9 minutes
- **Load**: 10-50 virtual users (gradual ramp)
- **Best for**: Performance baseline

### Stress Test
- **Use case**: Find breaking points
- **Duration**: ~15 minutes
- **Load**: 50-200 virtual users
- **Best for**: Capacity planning

### Spike Test
- **Use case**: Sudden traffic surge
- **Duration**: ~3 minutes
- **Load**: 10-100 virtual users (rapid spike)
- **Best for**: Resilience testing

## Custom Profiles

Create `profiles/load-profiles.yaml`:

```yaml
profiles:
  my-profile:
    stages:
      - duration: "2m"
        target: 10
        rampUp: "30s"
    thresholds:
      http_req_duration: ["p(95)<2000"]
      http_req_failed: ["rate<0.01"]
```

## Tips

1. **Start small**: Begin with smoke tests before running stress tests
2. **Monitor resources**: Watch CPU, memory, and network during tests
3. **Set realistic thresholds**: Base on actual SLA requirements
4. **Use different runners**: Distribute load tests across different machines
5. **Save artifacts**: Test results are automatically uploaded

