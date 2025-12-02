# GitLab CI/CD Usage Guide

This guide explains how to use the Postman to k6 load testing functionality in GitLab CI/CD pipelines.

## Overview

The GitLab CI configuration provides equivalent functionality to the GitHub Action, allowing you to:
- Convert Postman collections to k6 scripts at runtime
- Execute load tests with configurable profiles (smoke, load, stress, spike)
- Run tests in parallel across different profiles
- Collect and archive test results as artifacts

## Quick Start

### Basic Usage

Add to your `.gitlab-ci.yml`:

```yaml
include:
  - local: 'gitlab-ci-template.yml'  # Or use remote URL

stages:
  - test

load-test:
  extends: .postman-to-k6
  variables:
    POSTMAN_COLLECTION: "postman/collection.json"
    LOAD_PROFILE: "smoke"
```

### Running Multiple Profiles

```yaml
include:
  - local: 'gitlab-ci-template.yml'

stages:
  - test

load-test:
  extends: .postman-to-k6
  parallel:
    matrix:
      - LOAD_PROFILE: ["smoke", "load", "stress", "spike"]
  variables:
    POSTMAN_COLLECTION: "postman/collection.json"
```

## Configuration Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `POSTMAN_COLLECTION` | Path to Postman collection JSON file | Yes | `postman/collection.json` |
| `LOAD_PROFILE` | Load profile type: `smoke`, `load`, `stress`, or `spike` | No | `smoke` |
| `NODE_VERSION` | Node.js version for conversion | No | `18` |
| `PROFILES_CONFIG` | Path to load profiles YAML configuration | No | `profiles/load-profiles.yaml` |
| `K6_OPTIONS` | Additional k6 CLI options | No | `` |
| `ENVIRONMENT_FILE` | Path to Postman environment file | No | `` |

## GitLab CI Configuration Methods

### Method 1: Using the Template File Locally

1. Copy `gitlab-ci-template.yml` to your project
2. Include it in your `.gitlab-ci.yml`:

```yaml
include:
  - local: 'gitlab-ci-template.yml'

stages:
  - test

load-test:
  extends: .postman-to-k6
  variables:
    POSTMAN_COLLECTION: "postman/collection.json"
    LOAD_PROFILE: "load"
```

### Method 2: Using the Remote Template

```yaml
include:
  - remote: 'https://raw.githubusercontent.com/your-org/postman-to-k6-action/main/gitlab-ci-template.yml'

stages:
  - test

load-test:
  extends: .postman-to-k6
  variables:
    POSTMAN_COLLECTION: "postman/collection.json"
    LOAD_PROFILE: "load"
```

### Method 3: Direct Job Definition

Use the `.gitlab-ci.yml` file directly in your project, or copy the job definition:

```yaml
stages:
  - test

load-test:
  # Copy the .postman-to-k6-base job definition from .gitlab-ci.yml
  extends: .postman-to-k6-base
  variables:
    POSTMAN_COLLECTION: "postman/collection.json"
    LOAD_PROFILE: "smoke"
```

## Examples

### Example 1: Basic Smoke Test

```yaml
include:
  - local: 'gitlab-ci-template.yml'

stages:
  - test

smoke-test:
  extends: .postman-to-k6
  variables:
    POSTMAN_COLLECTION: "postman/collection.json"
    LOAD_PROFILE: "smoke"
  only:
    - main
    - merge_requests
```

### Example 2: Multiple Profiles with Matrix

```yaml
include:
  - local: 'gitlab-ci-template.yml'

stages:
  - test

load-test-all:
  extends: .postman-to-k6
  parallel:
    matrix:
      - LOAD_PROFILE: ["smoke", "load", "stress", "spike"]
  variables:
    POSTMAN_COLLECTION: "postman/collection.json"
  only:
    - main
    - schedules
```

### Example 3: Using Postman Environment File

```yaml
include:
  - local: 'gitlab-ci-template.yml'

stages:
  - test

load-test:
  extends: .postman-to-k6
  variables:
    POSTMAN_COLLECTION: "postman/collection.json"
    ENVIRONMENT_FILE: "postman/environment.json"
    LOAD_PROFILE: "load"
```

### Example 4: Custom k6 Options

```yaml
include:
  - local: 'gitlab-ci-template.yml'

stages:
  - test

load-test:
  extends: .postman-to-k6
  variables:
    POSTMAN_COLLECTION: "postman/collection.json"
    LOAD_PROFILE: "stress"
    K6_OPTIONS: "--out json=results.json --summary-export=summary.json"
```

### Example 5: Different Runners for Different Profiles

```yaml
include:
  - local: 'gitlab-ci-template.yml'

stages:
  - test

smoke-test:
  extends: .postman-to-k6
  tags:
    - docker
  variables:
    POSTMAN_COLLECTION: "postman/collection.json"
    LOAD_PROFILE: "smoke"

load-test:
  extends: .postman-to-k6
  tags:
    - self-hosted
  variables:
    POSTMAN_COLLECTION: "postman/collection.json"
    LOAD_PROFILE: "load"

stress-test:
  extends: .postman-to-k6
  tags:
    - self-hosted
    - high-memory
  variables:
    POSTMAN_COLLECTION: "postman/collection.json"
    LOAD_PROFILE: "stress"
```

### Example 6: Conditional Execution

```yaml
include:
  - local: 'gitlab-ci-template.yml'

stages:
  - test

load-test:
  extends: .postman-to-k6
  variables:
    POSTMAN_COLLECTION: "postman/collection.json"
    LOAD_PROFILE: "$LOAD_PROFILE"
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      variables:
        LOAD_PROFILE: "load"
    - if: $CI_COMMIT_BRANCH == "develop"
      variables:
        LOAD_PROFILE: "smoke"
    - when: manual
      variables:
        LOAD_PROFILE: "stress"
```

### Example 7: Using CI/CD Variables (GitLab UI)

Set variables in GitLab UI (Settings → CI/CD → Variables):

- `POSTMAN_COLLECTION`: `postman/collection.json`
- `LOAD_PROFILE`: `smoke`
- `NODE_VERSION`: `18`

Then in `.gitlab-ci.yml`:

```yaml
include:
  - local: 'gitlab-ci-template.yml'

stages:
  - test

load-test:
  extends: .postman-to-k6
  # Variables are automatically picked up from CI/CD Variables
```

## Load Profiles

### Smoke Test
- **Duration**: 1 minute
- **Virtual Users**: 5
- **Use case**: Quick validation

### Load Test
- **Duration**: ~9 minutes
- **Virtual Users**: 10-50 (gradual ramp)
- **Use case**: Normal expected load

### Stress Test
- **Duration**: ~15 minutes
- **Virtual Users**: 50-200
- **Use case**: Find breaking points

### Spike Test
- **Duration**: ~3 minutes
- **Virtual Users**: 10-100 (rapid spike)
- **Use case**: Sudden traffic surge

## Artifacts

Test results are automatically saved as artifacts:

- Generated k6 scripts (`k6-script*.js`)
- Profile configuration (`.k6-config/`)
- Test status files

Artifacts are available for 30 days by default and can be downloaded from the GitLab job page.

## Comparison: GitHub Actions vs GitLab CI

| Feature | GitHub Actions | GitLab CI |
|---------|---------------|-----------|
| Configuration | `action.yml` | `.gitlab-ci.yml` |
| Reusability | Composite Action | Template/Include |
| Inputs/Parameters | `inputs:` | `variables:` |
| Artifacts | `upload-artifact` action | `artifacts:` keyword |
| Runners | `runs-on:` | `tags:` |
| Matrix | `strategy.matrix` | `parallel.matrix` |
| Outputs | `outputs:` | Artifact files |
| Steps | `steps:` | `script:` sections |

## Key Differences from GitHub Actions

1. **Variables instead of Inputs**: GitLab CI uses variables instead of action inputs
2. **Artifacts**: GitLab uses `artifacts:` keyword instead of upload-artifact action
3. **Runners**: GitLab uses `tags:` to specify runners instead of `runs-on:`
4. **Outputs**: GitLab doesn't have direct outputs; use artifact files instead
5. **Templates**: GitLab uses `include` and `extends` for reusability

## Troubleshooting

### Collection Not Found

Ensure the path to your Postman collection is correct:

```yaml
variables:
  POSTMAN_COLLECTION: "postman/collection.json"  # Relative to repo root
```

### Profile Not Found

Check that the profile name matches exactly (case-sensitive) and exists in your `profiles/load-profiles.yaml` file.

### k6 Execution Fails

- Verify your Postman collection is valid JSON
- Check that API endpoints are accessible from GitLab runners
- Review job logs in GitLab CI/CD → Pipelines

### Permission Issues

Ensure your GitLab runners have:
- Network access to install packages
- Permissions to execute scripts
- Access to the repository files

## Best Practices

1. **Start with Smoke Tests**: Begin with smoke tests before running stress tests
2. **Use Parallel Execution**: Run multiple profiles in parallel using matrix strategy
3. **Set Realistic Thresholds**: Base thresholds on actual SLA requirements
4. **Use Dedicated Runners**: Run load tests on dedicated self-hosted runners when possible
5. **Version Control Configs**: Keep load profile configurations in version control
6. **Monitor Resources**: Watch CPU, memory, and network during tests
7. **Clean Up Artifacts**: Configure artifact expiration to manage storage

## Additional Resources

- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [k6 Documentation](https://k6.io/docs/)
- [Postman to k6 Converter](https://github.com/apideck-libraries/postman-to-k6)

## Support

For issues, questions, or contributions, please open an issue on the repository.

