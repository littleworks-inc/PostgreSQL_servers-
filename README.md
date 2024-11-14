# Azure PostgreSQL Servers Inventory Script

This Bash script generates a comprehensive inventory of all PostgreSQL servers across your Azure subscriptions, including storage metrics and configuration details.

## Features

- Automatically scans all subscriptions and resource groups
- Generates a detailed CSV report with server information
- Includes storage usage metrics
- Handles Azure authentication
- Performs prerequisite checks

## Prerequisites

- Azure CLI installed and configured
- `jq` command-line JSON processor
- `bc` calculator utility
- Bash shell environment
- Appropriate Azure permissions to:
  - List and access subscriptions
  - Read PostgreSQL server configurations
  - Access monitoring metrics

## Installation

1. Download the script:
   ```bash
   curl -O https://raw.githubusercontent.com/your-repo/postgres-inventory.sh
   ```

2. Make the script executable:
   ```bash
   chmod +x postgres-inventory.sh
   ```

## Usage

Simply run the script:
```bash
./postgres-inventory.sh
```

The script will:
1. Check for Azure CLI installation
2. Verify/prompt for Azure login
3. Scan all subscriptions and resource groups
4. Generate a CSV file with the inventory

## Output

The script generates a CSV file named `postgres_server_inventory_YYYYMMDD_HHMMSS.csv` containing the following information for each PostgreSQL server:

- Subscription ID
- Resource Group
- Server Name
- Location
- PostgreSQL Version
- Admin Login
- SKU Name
- Storage Profile (MB)
- Storage Used (GB)
- TLS Version
- Public Network Access Status
- Server State

## CSV Format

```csv
Subscription,Resource Group,Server Name,Location,Version,Admin Login,SKU Name,Storage Profile (MB),Storage Used (GB),TLS Version,Public Network Access,Server State
```

## Error Handling

The script includes error handling for:
- Missing Azure CLI installation
- Failed Azure authentication
- Resource access issues
- Missing required utilities

## Permissions Required

The Azure account used must have at least:
- Reader access to all target subscriptions
- Reader access to PostgreSQL servers
- Access to Azure Monitor metrics

## Limitations

- Storage metrics might show as "0" if monitoring data is not available
- Script execution time depends on the number of subscriptions and servers
- Requires active internet connection

## Troubleshooting

1. If Azure CLI is not installed:
   ```
   Error: Azure CLI is not installed. Please install it first.
   ```
   Solution: Install Azure CLI following the official documentation.

2. If login fails:
   ```
   Error: Azure login failed
   ```
   Solution: Verify your credentials and internet connection.

