#!/bin/bash

# Script will help to list all the PostgreSQL servers with storage details
# Version : 0.2

# Function to check if Azure CLI is installed
check_az_cli() {
    if ! command -v az &> /dev/null; then
        echo "Error: Azure CLI is not installed. Please install it first."
        echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
}

# Function to handle Azure login
azure_login() {
    echo "Checking Azure login status..."
    if ! az account show &> /dev/null; then
        echo "Not logged in. Initiating Azure login..."
        if ! az login; then
            echo "Error: Azure login failed"
            exit 1
        fi
        echo "Login successful!"
    else
        echo "Already logged into Azure"
        current_account=$(az account show --query user.name -o tsv)
        echo "Current account: $current_account"
    fi
}

# Function to get storage metrics for a server
get_storage_metrics() {
    local subscription=$1
    local resource_group=$2
    local server_name=$3
    
    local resource_id="/subscriptions/$subscription/resourceGroups/$resource_group/providers/Microsoft.DBforPostgreSQL/servers/$server_name"
    
    metrics=$(az monitor metrics list \
        --resource "$resource_id" \
        --metric storage_used \
        --aggregation Maximum \
        --query 'value[0].timeseries[0].data[0].maximum' \
        -o tsv 2>/dev/null || echo "0")
    
    # Convert bytes to GB
    local gb=$(echo "scale=2; $metrics / 1024 / 1024 / 1024" | bc)
    echo "$gb"
}

# Function to create and initialize CSV file
create_csv_file() {
    local output_file="postgres_server_inventory_$(date '+%Y%m%d_%H%M%S').csv"
    echo "Subscription,Resource Group,Server Name,Location,Version,Admin Login,SKU Name,Storage Profile (MB),Storage Used (GB),TLS Version,Public Network Access,Server State" > "$output_file"
    echo "$output_file"
}

# Function to check PostgreSQL servers in a resource group
check_resource_group() {
    local subscription_id=$1
    local resource_group=$2
    local csv_file=$3
    
    echo "  Checking Resource Group: $resource_group"
    
    servers=$(az postgres server list \
        --resource-group "$resource_group" \
        --query '[].{
            name:name,
            resourceGroup:resourceGroup,
            location:location,
            version:version,
            adminLogin:administratorLogin,
            skuName:sku.name,
            storageMb:storageProfile.storageMb,
            tlsVersion:minimalTlsVersion,
            publicNetworkAccess:publicNetworkAccess,
            state:userVisibleState
        }' \
        -o json)
    
    if [ "$(echo "$servers" | jq length)" -gt 0 ]; then
        echo "    Found PostgreSQL servers in $resource_group"
        echo "$servers" | jq -c '.[]' | while read -r server; do
            server_name=$(echo "$server" | jq -r '.name')
            location=$(echo "$server" | jq -r '.location')
            version=$(echo "$server" | jq -r '.version')
            admin_login=$(echo "$server" | jq -r '.adminLogin')
            sku_name=$(echo "$server" | jq -r '.skuName')
            storage_mb=$(echo "$server" | jq -r '.storageMb')
            tls_version=$(echo "$server" | jq -r '.tlsVersion')
            public_network=$(echo "$server" | jq -r '.publicNetworkAccess')
            server_state=$(echo "$server" | jq -r '.state')
            
            # Get storage usage in GB
            storage_used_gb=$(get_storage_metrics "$subscription_id" "$resource_group" "$server_name")
            
            echo "    - Found server: $server_name"
            echo "\"$subscription_id\",\"$resource_group\",\"$server_name\",\"$location\",\"$version\",\"$admin_login\",\"$sku_name\",\"$storage_mb\",\"$storage_used_gb\",\"$tls_version\",\"$public_network\",\"$server_state\"" >> "$csv_file"
        done
    else
        echo "    No PostgreSQL servers found in $resource_group"
    fi
}

# Main function to list PostgreSQL Servers
list_postgres_servers() {
    echo "Creating PostgreSQL servers inventory..."
    
    csv_file=$(create_csv_file)
    subscriptions=$(az account list --query "[].{SubscriptionId:id}" -o json)
    
    echo "$subscriptions" | jq -c '.[]' | while read -r sub; do
        sub_id=$(echo "$sub" | jq -r '.SubscriptionId')
        
        echo "Processing subscription: $sub_id"
        az account set --subscription "$sub_id" >/dev/null 2>&1
        
        # Get all resource groups in the subscription
        resource_groups=$(az group list --query '[].name' -o json)
        
        echo "$resource_groups" | jq -r '.[]' | while read -r rg; do
            check_resource_group "$sub_id" "$rg" "$csv_file"
        done
    done
    
    echo -e "\nInventory CSV file has been created: $csv_file"
}

# Main execution flow
echo "=== Azure PostgreSQL Servers Inventory Script ==="
echo "Checking prerequisites..."

check_az_cli
azure_login
list_postgres_servers
