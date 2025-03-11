# Terraform Module Publishing Pipeline Setup

This document explains how to set up the Azure DevOps pipeline for publishing the vSphere VM module to your Terraform Enterprise internal registry.

## Prerequisites

1. Azure DevOps organization and project
2. Access to a Terraform Enterprise instance with permissions to create/manage registry modules
3. Personal Access Token (PAT) with sufficient permissions in Azure DevOps

## Setup Steps

### 1. Set Up the Variable Groups

The pipeline requires two variable groups:

#### Terraform Enterprise Credentials

A variable group named `terraform-registry-credentials` with the following variables:

- `TFE_HOST`: URL of your Terraform Enterprise instance (e.g., `https://tfe.example.com`)
- `TFE_ORG`: Your organization name in Terraform Enterprise
- `TFE_USERNAME`: Username for authenticating with Terraform Enterprise
- `TFE_PASSWORD`: Password for authenticating with Terraform Enterprise

#### Artifactory Credentials

A variable group named `artifactory-credentials` with the following variables:

- `artifactoryUsername`: Username for authenticating with your internal Artifactory
- `artifactoryPassword`: Password for authenticating with your internal Artifactory
- `internalArtifactoryUrl`: URL of your internal Artifactory instance

You can create both variable groups using the provided PowerShell script:

```powershell
./create-variable-group.ps1 `
  -OrganizationUrl "https://dev.azure.com/your-org" `
  -ProjectName "your-project" `
  -PersonalAccessToken "your-pat" `
  -TfeHost "https://tfe.example.com" `
  -TfeOrg "your-tfe-org" `
  -TfeUsername "your-username" `
  -TfePassword "your-password" `
  -ArtifactoryUrl "https://artifactory.internal.example.com/artifactory" `
  -ArtifactoryUsername "your-artifactory-username" `
  -ArtifactoryPassword "your-artifactory-password"
```

### 2. Configure the Agent Pool

The pipeline uses an internal RHEL 9 agent pool. Ensure you have an agent pool set up with RHEL 9 agents:

1. Go to **Project Settings** > **Agent pools**
2. Create a new pool or use an existing one (e.g., `Enterprise-Linux-Pool`)
3. Ensure agents in this pool:
   - Run RHEL 9
   - Have access to your internal Artifactory instance
   - Have access to your internal RHEL repositories
   - Have sufficient permissions to install packages (sudo access)

### 3. Create the Pipeline

1. In your Azure DevOps project, go to **Pipelines** > **New Pipeline**
2. Select **Azure Repos Git** as your source
3. Select your repository
4. Select **Existing Azure Pipelines YAML file**
5. Enter the path to the pipeline YAML file: `/azure-pipelines.yml`
6. Click **Continue** 
7. Review the pipeline and update the agent pool name if needed (default is `Enterprise-Linux-Pool`)
8. Click **Save and run**

### 4. Set Up Required Permissions

The pipeline requires permissions to:

1. **Build and Test**: Basic build permissions
2. **Push Documentation Changes**: Contribute permissions to the repository 
3. **Create and Upload Modules**: Access to the Terraform Enterprise API

To grant the pipeline permissions to push documentation changes back to the repository:

1. Go to **Project Settings** > **Repositories** > **[Your Repository]** > **Security**
2. Find the build service identity (e.g., `[Project Name] Build Service ([Org Name])`)
3. Grant **Contribute** permission

### 5. Configure Terraform Enterprise

In your Terraform Enterprise organization:

1. Ensure you have a private registry namespace that matches the `moduleNamespace` variable in the pipeline
2. Create a module named `vsphere-vm` in that namespace
3. Set appropriate permissions for the module

### 6. Create the Environment

Create an environment named `terraform-registry` to control deployment approvals:

1. Go to **Pipelines** > **Environments** > **New environment**
2. Name it `terraform-registry`
3. Choose **None** for Resource
4. Configure any approval checks if needed

## Usage

Once set up, the pipeline will:

1. Automatically run on commits to the `main` branch and validate the module
2. Run all tests in the `tests` directory
3. Package the module
4. Publish the module to your Terraform Enterprise registry:
   - For commits to `main`, it will publish using the version in `version.tf`
   - For tags (e.g., `v1.0.0`), it will publish using the tag version

## Versioning

The module follows semantic versioning:

- Update the version in `version.tf` for minor changes or bug fixes
- For major releases, tag the repository (e.g., `git tag -a v1.0.0 -m "Release v1.0.0"`)

## Troubleshooting

Common issues and solutions:

- **Authentication Failures**: Check the credentials in the variable groups
- **Permission Errors**: Ensure the build service has required permissions
- **Module Already Exists**: Ensure each version is only published once
- **Documentation Not Updating**: Check if the build service has contribute permissions
- **Agent Connectivity Issues**: Verify agents can access internal Artifactory and RHEL repositories
- **Package Installation Failures**: Ensure agents have sudo permissions and access to repositories
- **RPM Path Issues**: Verify the correct paths to packages in Artifactory and adjust path variables as needed
- **Tool Installation Problems**: Check if the specific versions of required tools are available in your internal repositories

## Additional Resources

- [Azure DevOps Pipelines Documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/)
- [Terraform Enterprise API Documentation](https://www.terraform.io/docs/cloud/api/index.html)
- [Terraform Registry Module Requirements](https://www.terraform.io/docs/registry/modules/publish.html)