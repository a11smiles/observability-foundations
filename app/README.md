# ToDo App
<!-- markdownlint-disable-next-line MD036 -->
**Time Required: 20-30 minutes**

The application is a modified version of Microsoft's [Azure-Samples/cosmos-dotnet-core-todo-app](https://github.com/Azure-Samples/cosmos-dotnet-core-todo-app). The is version of the application has been modified for deployment simplicity and to illustrate proper instrumentation for logging events throughout the application. Admittedly, the logging could be arguable too much for such a simple application. However, the intension is to illustrate various logging levels and methodologies.

Deploying the application involves the following three steps:

- [ ] [Step 1: Build the application](#step-1-build-the-application)
- [ ] [Step 2: Prepare the environment for deployment](#step-2-prepare-the-environment-for-deployment)
- [ ] [Step 3: Deploy the application](#step-3-deploy-the-application)

## Step 1: Build the Application

As a prerequisite, you should already have .NET 6 SDK installed. The following instructions assume that this is the case. If not, please refer back to the [prerequisites](../README.md#prerequisites).

1. From the command or shell prompt, inside the `/app` folder, type the following:

   ```bash
   dotnet publish -c Release
   ```

This command will download all dependencies (make take a minute), then build a releasable version that's ready to publish to your website.

## Step 2: Prepare the Environment for Deployment

The previous step was pretty simple. This section will be slightly more involved as you will need to prepare your environment&mdash;local and remote&mdash;for deploying the application you just built.

1. From the command or shell prompt, enter into the `/app/bin/Release/net6.0/publish` folder.
2. Type the following commands (the second line ensures compatibility across platforms):  

   ```bash
   git init
   git branch -m master
   git add .
   git commit -m "First commit"
   ```

3. Next, you'll need to create a deployment username and password. Replace `<userid>` with your first name, Microsoft alias, or some other name. Whatever you chose, it must be _globally unique_, otherwise you'll receive an error asking you to use a different username.  Follow the instructions to create a password.

   ```bash
   az webapp deployment user set --user-name <userId>
   ```

4. Then use `config-local-git` to generate a Git URL. You'll need to do this for _both_ App Services (primary and secondary).

   ```bash
   az webapp deployment source config-local-git -g <resourceGroup> -n <primaryAppSiteName> --out tsv
   ```

   The above command will print something like the following:

   ```bash
   https://<userId>@<primaryAppSiteName>.scm.azurewebsites.net/<primaryAppSiteName>.git
   ```

   Copy the URL to the clipboard, and paste it into the next command.

5. Now add the remote repository for your primary site.

   ```bash
   git remote add primary <paste>
   ```

6. You just prepared your environment to deploy the application to the _primary_ site. You'll now need to repeat the previous two steps (steps 4 and 5) for the _secondary_ site. I've added the steps below for easy reference. (Remember that the first command will generate a URL that you'll need to copy and paste into the second command.)

   ```bash
   az webapp deployment source config-local-git -g <resourceGroup> -n <secondaryAppSiteName> --out tsv
   git remote add secondary <paste>
   ```

## Step 3: Deploy the application

Now that your environment has been properly configured, deploying your site is as simple as "pushing" it to both App Services.

1. Again, from the `/app/bin/Release/net6.0/publish` folder, deploy your application by pushing it to each of the the remote repositories. Each line deploys your the app to the respective App Service (primary and secondary).

   ```bash
   git push primary master
   git push secondary master
   ```

You'll be prompted to enter your password, and it may take a minute or two to upload all of the web app's artifacts. Just be patient.

Congratulations! If you've followed the instructions for deploying the infrastructure and the application, you should be able to interact with you application by visiting your app's `<trafficManagerUri>`.

You are now ready to configure the Grafana dashboards.
