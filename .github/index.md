# Github Action Workflows

[Github Actions](https://docs.github.com/en/actions) to automate, customize, and execute your software development workflows coupled with the repository.

## Local Actions

Validate Github Workflows locally with [Nekto's Act](https://nektosact.com/introduction.html). More info found in the Github Repo [https://github.com/nektos/act](https://github.com/nektos/act).

### Prerequisits
Assuming [Github CLI](https://github.com/cli/cli?tab=readme-ov-file#installation) and other applications have been pre-installed

Store the identical Secrets in Github Organization/Repository to local workstation

```
cat <<EOF > ~/creds/gcp.secrets
# Terraform.io Token
TF_API_TOKEN=[COPY/PASTE MANUALY]

# Github PAT
GITHUB_TOKEN=$(gh auth token)

# GCP
GCP_PROJECT=$(gcloud config get-value project)
GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)
GCP_IMPERSONATE_SERVICE_ACCOUNT_EMAIL=[COPY/PASTE MANUALY]
GCP_WORKLOAD_IDENTITY_PROVIDER=$(gcloud iam workload-identity-pools providers describe "${PROVIDER_NAME}" \
  --project="$(gcloud config get-value project)" \
  --location="global" \
  --workload-identity-pool="${WORKLOAD_IDENTITY_POOL_NAME}" \
  --format="value(name)")
EOF
```

### Refreshing local auth token
Local account impersonation authentication tokens only have a lifetime of 60 minutes.
Refresh often:

```
sed -i -E "s/(GOOGLE_OAUTH_ACCESS_TOKEN\=).*/\1$(gcloud auth print-access-token)/" ~/creds/gcp.secrets
```

### Manual Dispatch Testing

```
act -j terraform-dispatch-plan \
    -e .github/local.json \
    --secret-file ~/creds/gcp.secrets \
    --remote-name $(git remote show)

act -j terraform-dispatch-apply \
    -e .github/local.json \
    --secret-file ~/creds/gcp.secrets \
    --remote-name $(git remote show)

act -j terraform-dispatch-test \
    -e .github/local.json \
    --secret-file ~/creds/gcp.secrets \
    --remote-name $(git remote show) \
    --artifact-server-path /tmp/artifacts

act -j terraform-dispatch-destroy \
    -e .github/local.json \
    --secret-file ~/creds/gcp.secrets \
    --remote-name $(git remote show)
```

### Integration Testing

```
# Create an artifact location to upload/download between steps locally
mkdir /tmp/artifacts

# Run the full Integration test with
act -j terraform-integration-plan \
  -e .github/local.json \
  --secret-file ~/creds/gcp.secrets \
  --remote-name $(git remote show) \
  --artifact-server-path /tmp/artifacts

act -j terraform-integration-destroy \
  -e .github/local.json \
  --secret-file ~/creds/gcp.secrets \
  --remote-name $(git remote show) \
  --artifact-server-path /tmp/artifacts

```

### Unit Testing

```
act -j terraform-unit-tests \
    -e .github/local.json \
    --secret-file ~/creds/gcp.secrets \
    --remote-name $(git remote show)
```