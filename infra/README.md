# Azure Infrastructure
<!-- markdownlint-disable-next-line MD036 -->
**Time Required: 20-30 minutes**

The included bicep scripts will deploy a handful of resources to your Azure subscription, including registering a domain name that you will use to access your load-balanced site via SSL.

Deploying the infrastructure involves the following two steps:

- [ ] [Step 1: Update parameters](#step-1-update-parameters)
- [ ] [Step 2: Deploy bicep](#step-2-deploy-bicep)

Upon completion of these two steps, you will have an environment that is comprised of two App Services load-balanced with a Traffic Manager and a Cosmos DB backend. The infrastructure looks like the following diagram.
<!-- markdownlint-disable MD033 -->
<div style="padding:20px;text-align:center;">
<img src="./topology.svg" />
</div>
<!-- markdownlint-enable MD033 -->

## Step 1: Update Parameters

In order to run the script, you will need to modify the `main.params.json` file and supply values for the parameters contained therein. Below is a list of the parameters, what they are for, and any particular notes to be aware of.

| Parameter | Description | Notes |
| :-        | :-          | :-           |
| `primaryRegion` | Primary region of the application | Must be fully qualified (e.g., "East US 2"). |
| `secondaryRegion` | Secondary region of the application | Again, must be fully qualified. |
| `cosmosdbFailoverRegion` | A failover region for cosmos db | Again, must be fully qualified. |
| `domainPrimaryDomain` | TLD domain name (e.g., contoso.com) | This must be an unregistered domain name. Check with GoDaddy or another service to make sure the domain is available before attempting to run this. |
| `domainPrimaryEmail` | Primary contact's email address for domain registration | This must be a non-Microsoft email address.|
| `domainPrimaryFirstName` | Primary contact's first name for domain registration | |
| `domainPrimaryLastName` | Primary contact's last name for domain registration | |
| `domainPrimaryPhone` | Primary contact's phone number for domain registration | The format should be +#.##########, where the first number is your country code and the last numbers (after the period) are the remainder of your number, including area code (ex. +1.5556667777).<br /><br />The country code can be one to three numbers. |
| `domainPrimaryAddress1` | Primary contact's address line 1 | |
| `domainPrimaryAddress2` | Primary contact's address line 2, if needed | If this isn't needed, you can leave the field empty. |
| `domainPrimaryCity` | Primary contact's address city | |
| `domainPrimaryCountry` | Primary contact's address country abbreviation (e.g., US) | Must be in two-letter format. |
| `domainPrimaryPostalCode` | Primary contact's address postal code | |
| `domainPrimaryState` | Primary contact's address state/region (e.g., WA, San Jose, etc.) | |
| `myIPAddress` | Your _public_ IP address | This is used for domain registration consent. To find your IP address, go to [WhatIsMyIP](https://www.whatismyip.com/ and copy the IPv4 address from the top of the page.

Once you've updated the parameters file and saved it, you are ready to deploy the infrastructure to Azure.

## Step 2: Deploy Bicep

> **NOTES:**  
>
> 1. Given occasional race conditions with ARM, you may need to run this script more than once for everything to pass.  
> 2. Microsoft sponsored account may not allow App Service Domains, or there is a limit. You may need to request a limit increase.
> 3. Cosmos DB may limit your failover region due to resource constraints. If Azure throws an error, update your failover domain and rerun the scripts.

1. In the Azure portal, create a resource group to hold you application.
2. Open a prompt and login to your Azure subscription using `az login`.
3. Make sure you've selected the correct subscription (use `az account set --subscription <subscriptionId>` replacing _\<subscriptionId\>_ with your subscription's Id, if necessary)
4. Now, run the following command, while replacing _\<resourceGroup\>_ with the name of the resource group you created in step 1.

   ```bash
   az deployment group create 
     --resource-group <resourceGroup>
     --template-file main.bicep 
     --parameters main.params.json 
     --query properties.outputs
   ```

The script may take 5-10 minutes to complete, depending on how long it takes to deploy Cosmos DB. Upon completion, the script will output JSON with the configured resources and their information.

> **IMPORTANT: You will need to save this information for future steps. Either open a new command prompt or shell window, or copy and paste the JSON to a temporary document for referencing later.**

### Variable References

The output will contain a number of variables in the following format:

```json
{
  "variableName": {
    "type": "String",
    "value": "variableValue"
  }
}
```

Unless specified, throughout the remainder of the deployment instructions (in the other sections), you will see these variables referenced as `<variableName>`. Where you see `<variableName>`, you will need to replace it with its `variableValue`.

For example, some of the variables returned will include the following (yours will be different):

```json
{
  "resourceGroup": {
    "type": "String",
    "value": "grafana-demo"
  },
  "primaryAppSiteName": {
    "type": "String",
    "value": "grafana-demo-primary"
  }
}
```

In future steps, you may be told to enter a command like the following:

```bash
az webapp deployment source config-local-git -g <resourceGroup> -n <primaryAppSiteName> --out tsv
```

You would simply substitute the variable values for the referenced variables like so:

```bash
az webapp deployment source config-local-git -g grafana-demo -n grafana-demo-primary --out tsv
```

Make sure you keep the information handy. Either open another command prompt or copy-paste the information to a temporary document (e.g., VS Code, Notepad, Word, etc.).

You have now successfully deployed the infrastructure. You are ready to build and deploy the application.

<!-- markdownlint-disable MD033 -->
<div style="display:flex;flex-direction:row;justify-content:space-between;padding-top:30px;">
  <style>
    .button {
      color: #ffffff !important;
      background-color: #2d63c8 !important;
      font-size: 19px;
      border: 1px solid #2d63c8;
      border-radius: 3px;
      padding: 8px 20px;
      cursor: pointer;
    }
    .button.disabled {
      background-color:#ccc !important;
      color: #999 !important;
      cursor: default;
    }
    .button:not(.disabled):hover {
      color: #2d63c8 !important;
      background-color: #ffffff !important;
    }
  </style>
  <a class="button disabled" type="button">Previous</a>
  <a class="button" href="../app/README.md">Next</a>
</div>
