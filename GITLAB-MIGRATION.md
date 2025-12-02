# Migrating from GitHub Actions to GitLab CI

This guide helps you migrate from using the GitHub Action to GitLab CI/CD.

## Quick Comparison

| Aspect | GitHub Actions | GitLab CI |
|--------|---------------|-----------|
| **File** | `action.yml` | `.gitlab-ci.yml` or `gitlab-ci-template.yml` |
| **Usage** | `uses: your-org/postman-to-k6-action@v1` | `extends: .postman-to-k6` |
| **Parameters** | `with:` inputs | `variables:` |
| **Artifacts** | `upload-artifact` action | `artifacts:` keyword |
| **Runners** | `runs-on:` | `tags:` |
| **Matrix** | `strategy.matrix` | `parallel.matrix` |
| **Reusability** | Composite Action | Template/Include |

## Step-by-Step Migration

### Step 1: Copy Files to Your Project

**Option A: Use Template File**
```bash
# Copy the template to your project
cp gitlab-ci-template.yml .gitlab-ci-template.yml
```

**Option B: Include from Remote**
```yaml
include:
  - remote: 'https://raw.githubusercontent.com/your-org/postman-to-k6-action/main/gitlab-ci-template.yml'
```

### Step 2: Convert Your Workflow

#### GitHub Actions Example:
```yaml
name: Load Testing
on:
  workflow_dispatch:

jobs:
  load-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: your-org/postman-to-k6-action@v1
        with:
          postman-collection: 'postman/collection.json'
          load-profile: 'smoke'
```

#### GitLab CI Equivalent:
```yaml
include:
  - local: 'gitlab-ci-template.yml'

stages:
  - test

load-test:
  extends: .postman-to-k6
  variables:
    POSTMAN_COLLECTION: "postman/collection.json"
    LOAD_PROFILE: "smoke"
```

### Step 3: Parameter Mapping

| GitHub Action Input | GitLab CI Variable | Example |
|---------------------|-------------------|---------|
| `postman-collection` | `POSTMAN_COLLECTION` | `"postman/collection.json"` |
| `load-profile` | `LOAD_PROFILE` | `"smoke"` |
| `environment-file` | `ENVIRONMENT_FILE` | `"postman/environment.json"` |
| `profiles-config` | `PROFILES_CONFIG` | `"profiles/load-profiles.yaml"` |
| `k6-options` | `K6_OPTIONS` | `"--out json=results.json"` |
| `node-version` | `NODE_VERSION` | `"18"` |
| `runner-label` | `tags:` | `["docker"]` |

### Step 4: Matrix Strategy Conversion

#### GitHub Actions:
```yaml
jobs:
  load-test:
    strategy:
      matrix:
        profile: [smoke, load, stress, spike]
    steps:
      - uses: your-org/postman-to-k6-action@v1
        with:
          load-profile: ${{ matrix.profile }}
```

#### GitLab CI:
```yaml
load-test:
  extends: .postman-to-k6
  parallel:
    matrix:
      - LOAD_PROFILE: ["smoke", "load", "stress", "spike"]
  variables:
    POSTMAN_COLLECTION: "postman/collection.json"
```

### Step 5: Runner Configuration

#### GitHub Actions:
```yaml
jobs:
  load-test:
    runs-on: self-hosted
```

#### GitLab CI:
```yaml
load-test:
  extends: .postman-to-k6
  tags:
    - self-hosted
```

### Step 6: Conditional Execution

#### GitHub Actions:
```yaml
jobs:
  load-test:
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: your-org/postman-to-k6-action@v1
```

#### GitLab CI:
```yaml
load-test:
  extends: .postman-to-k6
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  variables:
    POSTMAN_COLLECTION: "postman/collection.json"
```

### Step 7: Manual Triggers

#### GitHub Actions:
```yaml
on:
  workflow_dispatch:
    inputs:
      profile:
        type: choice
        options: [smoke, load, stress, spike]
```

#### GitLab CI:
```yaml
load-test:
  extends: .postman-to-k6
  when: manual
  variables:
    POSTMAN_COLLECTION: "postman/collection.json"
    LOAD_PROFILE: "$LOAD_PROFILE"  # Set via CI/CD Variables or pipeline variables
```

## Complete Example Migration

### Before (GitHub Actions):
```yaml
name: Load Testing

on:
  workflow_dispatch:
    inputs:
      profile:
        type: choice
        options: [smoke, load, stress, spike]
        default: smoke

jobs:
  load-test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        profile: [smoke, load]
    steps:
      - uses: actions/checkout@v4
      - uses: your-org/postman-to-k6-action@v1
        with:
          postman-collection: 'postman/collection.json'
          load-profile: ${{ matrix.profile }}
          environment-file: 'postman/environment.json'
          k6-options: '--out json=results.json'
```

### After (GitLab CI):
```yaml
include:
  - local: 'gitlab-ci-template.yml'

stages:
  - test

load-test:
  extends: .postman-to-k6
  parallel:
    matrix:
      - LOAD_PROFILE: ["smoke", "load"]
  variables:
    POSTMAN_COLLECTION: "postman/collection.json"
    ENVIRONMENT_FILE: "postman/environment.json"
    K6_OPTIONS: "--out json=results.json"
  only:
    - main
    - merge_requests
```

## Common Patterns

### Pattern 1: Branch-Based Profiles

**GitHub Actions:**
```yaml
jobs:
  load-test:
    steps:
      - uses: your-org/postman-to-k6-action@v1
        with:
          load-profile: ${{ github.ref == 'refs/heads/main' && 'load' || 'smoke' }}
```

**GitLab CI:**
```yaml
load-test:
  extends: .postman-to-k6
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      variables:
        LOAD_PROFILE: "load"
    - if: $CI_COMMIT_BRANCH != "main"
      variables:
        LOAD_PROFILE: "smoke"
  variables:
    POSTMAN_COLLECTION: "postman/collection.json"
```

### Pattern 2: Scheduled Tests

**GitHub Actions:**
```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
```

**GitLab CI:**
```yaml
load-test:
  extends: .postman-to-k6
  only:
    - schedules
  variables:
    POSTMAN_COLLECTION: "postman/collection.json"
    LOAD_PROFILE: "load"
```

### Pattern 3: Artifact Handling

**GitHub Actions:**
```yaml
- uses: actions/upload-artifact@v4
  with:
    name: k6-results
    path: k6-script*.js
```

**GitLab CI:**
```yaml
# Already configured in template via artifacts: keyword
# Results are automatically saved
```

## Key Differences to Remember

1. **No Checkout Needed**: GitLab CI automatically checks out code
2. **Variables vs Inputs**: Use `variables:` instead of `with:`
3. **Case Sensitivity**: GitLab CI variables are case-sensitive and typically UPPERCASE
4. **Artifacts**: Automatically handled via `artifacts:` keyword
5. **Outputs**: Use artifact files instead of step outputs
6. **Conditional Logic**: Use `rules:` instead of `if:` at job level

## Testing Your Migration

1. **Create a test branch** with your GitLab CI configuration
2. **Set CI/CD variables** in GitLab UI if needed (Settings → CI/CD → Variables)
3. **Run a manual pipeline** to test
4. **Compare results** with your GitHub Actions output
5. **Verify artifacts** are created correctly

## Troubleshooting

### Issue: Job fails with "command not found"
**Solution**: The template handles installations automatically. Check that your runner has network access.

### Issue: Variables not recognized
**Solution**: Ensure variables are defined in `variables:` section or in GitLab CI/CD Variables settings.

### Issue: Artifacts not appearing
**Solution**: Check `artifacts:` configuration in the template. Artifacts are created automatically.

### Issue: Profile not found
**Solution**: Verify the profile name matches exactly (case-sensitive) in your `profiles/load-profiles.yaml`.

## Additional Resources

- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [GitLab CI Variables](https://docs.gitlab.com/ee/ci/variables/)
- [GitLab CI Artifacts](https://docs.gitlab.com/ee/ci/pipelines/job_artifacts.html)
- [GitLab Usage Guide](GITLAB-USAGE.md)

## Need Help?

If you encounter issues during migration:
1. Check the [GitLab Usage Guide](GITLAB-USAGE.md) for detailed examples
2. Review the example files (`.gitlab-ci.example.yml`)
3. Open an issue on the repository

