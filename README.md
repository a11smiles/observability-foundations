# Observability Foundations

This repo contains artifacts that are intended to enable Microsoft CSAs and partners to have initial conversations regarding observability of their Azure workloads. Within this repo exists a demo application, sample Grafana dashboards, and a k6 script for load testing the application. Please read the respective deployment guides.

## Content

There are four primary artifacts within this repo. Each artifact has its own configuration/deployment guide. I've attempted to be as detailed as possible with intention to simplify deployments and have you up and running quickly. Below is the basic outline of procedures.

> **NOTE:** Once you have Git installed, you should clone this repository to your local machine. Otherwise, [download](https://github.com/Azure/observability-foundations/archive/refs/heads/main.zip) the zip file and extract it on your local machine. **DO NOT ATTEMPT TO RUN THIS IN THE PORTAL's CLI.**

### Prerequisites

In order to deploy the demo and use the include artifacts, you will need the following.

1. [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
2. Latest version of Azure Bicep (execute `az bicep upgrade` after the Azure CLI has been installed)
3. [Git CLI](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
4. [.NET 6 SDK](https://dotnet.microsoft.com/download/dotnet/6.0)
5. [Grafana](https://grafana.com/auth/sign-up/create-user)
6. [k6 Runtime](https://k6.io/docs/get-started/installation/)
7. PowerPoint (to view the PPT)

### Source and Deployment

The locations and deployment guides are listed below. You will need to deploy  the artifacts (if necessary) in the following order.
<!-- markdownlint-disable-next-line MD036 -->
**Total time required: 1-2 hours**

| Artifact | Folder | Deployment Guide | Time Required  |
| :-       | :-     | :-               | -:            |
| PowerPoint Deck (no deployment) | [./assets](./assets) | [observability-fundamentals.ppt](./assets/observability-fundamentals.pptx) | -- |
| Presentation Guide (no deployment) | [./assets](./assets) | [observability-fundamentals.docx](./assets/observability-fundamentals.docx) | -- |
| Azure Infrastructure | [./infra](./infra) | [README.md](./infra/README.md) | 20-30 minutes
| ToDo App | [./app](./app) | [README.md](./app/README.md) | 20-30 minutes
| Grafana Dashboards | [./dashboards](./dashboards) | [README.md](./dashboards/README.md) | 45-60 minutes |
| k6 Script | [./k6](./k6) | [README.md](./k6/README.md) | 10-15 minutes |

## Contributing

This project, while made available on GitHub as Open Source, limits community contributions. It is maintained by [a11smiles](https://github.com/a11smiles) as a resource for Microsoft CSAs and partners to use for delivering conversations regarding observability with Azure Monitor and Grafana. While you may wish to contribute, not all PRs will be honored. Please discuss prior to spending effort. You may wish to consider opening an Issue instead.

## Copyright

All content in this repository has been developed by Joshua Davis and is Copyrighted &copy; 2023 by [Missional, Inc.](https://missional.dev). All rights reserved. It is [licensed](./LICENSE) under MIT for use by Microsoft and its partners. Microsoft, Azure, and respective products are registered trademarks of Microsoft. However, all content remains the intellectual property of Joshua Davis and Missional, Inc.

## Warranty

There is no warranty, written or implied, or official support for the artifacts contained herein. Use at your own discretion.
