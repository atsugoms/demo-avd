#!/bin/bash

# Azure Virtual Desktop ARM Template Deployment Script
# This script creates a resource group and deploys the AVD infrastructure

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
LOCATION="japaneast"
PROJECT="at-avd"
ENVIRONMENT="dev"
SESSION_HOST_COUNT=1
SESSION_HOST_VM_SIZE="Standard_B2as_v2"
SESSION_HOST_ADMIN_USERNAME="azureuser"

# Function to print messages
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to print usage
print_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    -s, --subscription-id ID        Azure Subscription ID (required)
    -t, --tenant-id ID             Azure Tenant ID (required)
    -p, --project NAME             Project name (default: at-avd)
    -e, --environment ENV          Environment name (default: dev)
    -l, --location LOCATION        Azure region (default: japaneast)
    -u, --username USERNAME        Session host admin username (default: azureuser)
    -w, --password PASSWORD        Session host admin password (required)
    -c, --count COUNT              Number of session hosts (default: 1)
    -v, --vm-size SIZE             Session host VM size (default: Standard_B2as_v2)
    -n, --deployment-name NAME     Deployment name (default: avd-deployment)
    -a, --artifacts-location URL   Base URI for linked templates (default: GitHub main branch raw URL)
    -d, --dry-run                  Validate template without deploying
    -h, --help                     Show this help message

EXAMPLE:
    $0 -s e278bdad-714d-401a-a47c-349b04f163ae \\
       -t 772d181e-a36c-44c0-ac2b-6f70d3b3baf2 \\
       -e arm01 \\
       -w MySecurePassword123!

EOF
}

# Parse arguments
SUBSCRIPTION_ID=""
TENANT_ID=""
SESSION_HOST_ADMIN_PASSWORD=""
DEPLOYMENT_NAME="avd-deployment"
ARTIFACTS_LOCATION=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--subscription-id)
            SUBSCRIPTION_ID="$2"
            shift 2
            ;;
        -t|--tenant-id)
            TENANT_ID="$2"
            shift 2
            ;;
        -p|--project)
            PROJECT="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -u|--username)
            SESSION_HOST_ADMIN_USERNAME="$2"
            shift 2
            ;;
        -w|--password)
            SESSION_HOST_ADMIN_PASSWORD="$2"
            shift 2
            ;;
        -c|--count)
            SESSION_HOST_COUNT="$2"
            shift 2
            ;;
        -v|--vm-size)
            SESSION_HOST_VM_SIZE="$2"
            shift 2
            ;;
        -n|--deployment-name)
            DEPLOYMENT_NAME="$2"
            shift 2
            ;;
        -a|--artifacts-location)
            ARTIFACTS_LOCATION="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$SUBSCRIPTION_ID" ]]; then
    print_error "Subscription ID is required (-s or --subscription-id)"
    print_usage
    exit 1
fi

if [[ -z "$TENANT_ID" ]]; then
    print_error "Tenant ID is required (-t or --tenant-id)"
    print_usage
    exit 1
fi

if [[ -z "$SESSION_HOST_ADMIN_PASSWORD" ]]; then
    print_error "Session host admin password is required (-w or --password)"
    print_usage
    exit 1
fi

# Calculate resource group name
RESOURCE_GROUP_NAME="${PROJECT}-${ENVIRONMENT}-rg"

print_message "Starting Azure Virtual Desktop deployment"
print_message "=========================================="
print_message "Subscription ID: $SUBSCRIPTION_ID"
print_message "Tenant ID: $TENANT_ID"
print_message "Project: $PROJECT"
print_message "Environment: $ENVIRONMENT"
print_message "Resource Group: $RESOURCE_GROUP_NAME"
print_message "Location: $LOCATION"
print_message "Session Hosts: $SESSION_HOST_COUNT (${SESSION_HOST_VM_SIZE})"
print_message "Deployment Name: $DEPLOYMENT_NAME"
print_message "=========================================="
echo ""

# Set subscription context
print_message "Setting Azure subscription context..."
az account set --subscription "$SUBSCRIPTION_ID"

# Check if resource group exists
print_message "Checking resource group..."
if az group exists --name "$RESOURCE_GROUP_NAME" | grep -q true; then
    print_warning "Resource group '$RESOURCE_GROUP_NAME' already exists"
else
    print_message "Creating resource group '$RESOURCE_GROUP_NAME' in $LOCATION..."
    az group create \
        --name "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION"
fi

echo ""
print_message "Preparing deployment parameters..."

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEMPLATE_FILE="$SCRIPT_DIR/main.json"
PARAMETERS_FILE="$SCRIPT_DIR/parameters.json"

# Check if template and parameters files exist
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    print_error "Template file not found: $TEMPLATE_FILE"
    exit 1
fi

echo ""
if [[ "$DRY_RUN" == true ]]; then
    print_message "Running template validation (dry-run mode)..."
    VALIDATE_PARAMS=(tenantId="$TENANT_ID" prj="$PROJECT" env="$ENVIRONMENT" location="$LOCATION" \
        sessionHostVmSize="$SESSION_HOST_VM_SIZE" sessionHostAdminUsername="$SESSION_HOST_ADMIN_USERNAME" \
        sessionHostAdminPassword="$SESSION_HOST_ADMIN_PASSWORD" sessionHostCount=$SESSION_HOST_COUNT)
    if [[ -n "$ARTIFACTS_LOCATION" ]]; then
        VALIDATE_PARAMS+=(_artifactsLocation="$ARTIFACTS_LOCATION")
    fi

    az deployment group validate \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --template-file "$TEMPLATE_FILE" \
        --parameters "${VALIDATE_PARAMS[@]}"
    
    if [[ $? -eq 0 ]]; then
        print_message "Template validation successful!"
        echo ""
        print_message "Dry-run completed. To deploy, run without -d flag."
    fi
else
    print_message "Deploying template to resource group..."
    echo ""
    
    DEPLOY_PARAMS=(tenantId="$TENANT_ID" prj="$PROJECT" env="$ENVIRONMENT" location="$LOCATION" \
        sessionHostVmSize="$SESSION_HOST_VM_SIZE" sessionHostAdminUsername="$SESSION_HOST_ADMIN_USERNAME" \
        sessionHostAdminPassword="$SESSION_HOST_ADMIN_PASSWORD" sessionHostCount=$SESSION_HOST_COUNT)
    if [[ -n "$ARTIFACTS_LOCATION" ]]; then
        DEPLOY_PARAMS+=(_artifactsLocation="$ARTIFACTS_LOCATION")
    fi

    az deployment group create \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$DEPLOYMENT_NAME" \
        --template-file "$TEMPLATE_FILE" \
        --parameters "${DEPLOY_PARAMS[@]}"
    
    if [[ $? -eq 0 ]]; then
        echo ""
        print_message "=========================================="
        print_message "Deployment completed successfully!"
        print_message "=========================================="
        print_message "Resource Group: $RESOURCE_GROUP_NAME"
        print_message ""
        print_message "To check deployment status, run:"
        echo "    az deployment group show --resource-group $RESOURCE_GROUP_NAME --name $DEPLOYMENT_NAME"
        echo ""
        print_message "To list deployed resources, run:"
        echo "    az resource list --resource-group $RESOURCE_GROUP_NAME"
    else
        print_error "Deployment failed!"
        exit 1
    fi
fi

exit 0
