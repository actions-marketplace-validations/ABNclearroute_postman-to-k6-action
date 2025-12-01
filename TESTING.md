# Testing Guide

This guide explains how to test the Postman to k6 Action on GitHub using the provided sample collection.

## Sample Postman Collection

A sample Postman collection is included at `postman/collection.json` that tests the [JSONPlaceholder API](https://jsonplaceholder.typicode.com/posts).

### Collection Details

- **API Endpoint**: `https://jsonplaceholder.typicode.com/posts`
- **Request Type**: GET
- **Tests Included**: Status code validation, response time checks, and data structure validation

## How to Test

### Option 1: Using the Test Workflow (Recommended)

The repository includes a ready-to-use test workflow at `.github/workflows/test.yml`.

1. **Go to Actions Tab**: Navigate to the "Actions" tab in your GitHub repository
2. **Select Test Workflow**: Click on "Test Postman to k6 Action" in the workflow list
3. **Run Workflow**: Click "Run workflow" button
4. **Choose Branch**: Select the branch (usually `main`)
5. **Start**: Click "Run workflow"

The workflow will:
- Run a smoke test automatically
- Optionally run all profiles (smoke, load, stress, spike) in parallel

### Option 2: Using the Example Workflow

1. **Go to Actions Tab**: Navigate to the "Actions" tab
2. **Select Example Workflow**: Click on "Postman to k6 Load Testing Example"
3. **Run Workflow**: Click "Run workflow"
4. **Configure Inputs**:
   - **Postman Collection**: `postman/collection.json` (default)
   - **Load Profile**: Choose from smoke, load, stress, or spike
5. **Start**: Click "Run workflow"

### Option 3: Create Your Own Workflow

Create a new workflow file in `.github/workflows/`:

```yaml
name: My Load Test

on:
  workflow_dispatch:

jobs:
  load-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Postman to k6 Load Test
        uses: ./
        with:
          postman-collection: 'postman/collection.json'
          load-profile: 'smoke'
```

## What to Expect

When the workflow runs, it will:

1. ✅ **Validate** the Postman collection JSON
2. ✅ **Convert** the collection to a k6 script
3. ✅ **Apply** the selected load profile configuration
4. ✅ **Execute** k6 with the configured VUs and duration
5. ✅ **Upload** test results as artifacts

### Smoke Test Example Output

```
✓ Status code is 200
✓ Response time is less than 2000ms
✓ Response has array of posts
✓ Each post has required fields
```

### Viewing Results

1. **Workflow Summary**: Check the workflow run summary for test status
2. **Artifacts**: Download artifacts to see generated k6 scripts and results
3. **Logs**: Review the workflow logs for detailed execution information

## Expected Results

For the JSONPlaceholder API test:

- ✅ **Status Code**: 200 OK
- ✅ **Response Time**: < 2000ms (typically much faster)
- ✅ **Data**: Array of 100 posts
- ✅ **Fields**: Each post has `id`, `title`, `body`, and `userId`

## Troubleshooting

### Workflow Fails at Collection Validation

- Check that `postman/collection.json` exists
- Verify the JSON is valid (you can use `python3 -m json.tool postman/collection.json`)

### k6 Execution Fails

- Verify the API endpoint is accessible from GitHub Actions runners
- Check network connectivity in workflow logs
- Review k6 error messages in the logs

### Profile Not Found

- Ensure `profiles/load-profiles.yaml` exists
- Verify the profile name matches exactly (case-sensitive)
- Check the `profiles-config` input path

## Next Steps

After successful testing:

1. **Customize Load Profiles**: Edit `profiles/load-profiles.yaml` to match your requirements
2. **Add Your Collections**: Replace or add to `postman/collection.json` with your own API tests
3. **Integrate in CI/CD**: Add the action to your existing workflows
4. **Share with Team**: Make the repository available for your team to use

## Additional Resources

- [JSONPlaceholder API Documentation](https://jsonplaceholder.typicode.com/)
- [k6 Documentation](https://k6.io/docs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

