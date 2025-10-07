# S3 Storage Browser – Setup & Terraform Integration

## 1) Purpose & Scope

A lightweight web-based storage browser that lets non-AWS users securely browse and manage objects in a specific S3 bucket via Cognito-backed authentication (switching to AzureAD). This document explains:

* How the browser works conceptually
* Deployment and local development
* Current architecture and security model
* The Terraform resources we manage (bucket, CORS, IAM policies & attachments)
* How Amplify/Cognito integrates

---

## 2) High-Level Architecture

```
[User Browser]
    |  (HTTPS)
    v
[Amplify Web App  (https://main.d2k5uxsf6lu8a3.amplifyapp.com)]
    |  AuthN via Cognito (User Pool + Identity Pool)
    v
[Cognito Identity Pool issues AWS credentials]
    |  temp creds assume IAM role based on auth state / groups
    v
[S3 Bucket: loan-optimization-test (eu-west-1)]
   ├── public/*   (guests: read/list; auth: R/W/D)
   └── admin/*    (auth: R/W/D; admin group: R/W/D)
```

Key points:

* The bucket remains **private** (no public ACL/policy). Access is via IAM roles only.
* CORS is configured on the bucket to allow the Amplify app and local dev origins.
* Credentials are obtained via Cognito Identity Pool; the role chosen depends on whether the user is unauthenticated, authenticated, or in the **admin** group.

---
## 3) How the deployment works
* Create the S3 Bucket and the necessary roles/policies using the terraform code `terraform apply`
* You might have to deploy the bucket first before deploying the policies because AWS Amplify creates the user groups and roles using Cognito (this can be done using the `-target` flag)
* Once the bucket has been created, we can deploy our Frontend that now points to the S3 Bucket, see the section `Frontend Deployment` below 
* If all went well, you should now have access to the S3 Bucket via the frontend application

## 4) Frontend Deployment

Our frontend is deployed straight from the Git repository using **AWS Amplify Hosting**. This gives us CI/CD, preview builds per PR, and automatic cache invalidation.
There is no support for deploying directly from an ADO Repo, so we have two options, create a mirror repo with one of the supported Git providers or setup an ADO pipeline which builds the frontend and deploys it via the CLI or an S3 Bucket.


### Flow

1. **Connect Repo & Branch**

    * Amplify Console → *New app* → *Host web app* → choose provider (GitHub/GitLab/Bitbucket/CodeCommit) → select the repo + the branch (e.g., `main`).
2. **Local Development**

   * We can run the frontend locally by running the `npm run dev` but first, we need the env file from amplify. This file can be found on `Amplify Console -> Select your app -> Main Branch -> Deployed backend resources -> Download amplify_outputs.json` and place this file in the root of the frontend repo

3. **Environment variables & secrets**

   * Configure in Amplify Console → *App settings* → *Environment variables*. Never commit secrets.

### Ops Notes

* If you add a new frontend origin (e.g., staging domain), **update Terraform CORS** and re-apply.
* Keep the **region** and **bucket name** consistent between Terraform and frontend configuration.
* Use separate branches/environments for dev/test/prod; Amplify can host each from a different branch.

---
## 5) Access Model (Least Privilege)

* **Paths**

  * `public/*` → Auth users can `Get/Put/Delete`; Admins implicitly allowed via Auth policy.
  * `admin/*` → Auth users and Admin group can `Get/Put/Delete`. Admin group also has its own policy so we can tighten auth later without breaking admins.
* **List vs Object actions**

  * `s3:ListBucket` applies to **bucket ARN only** and is restricted using `s3:prefix` conditions.
  * `Get/Put/DeleteObject` apply to **object ARNs** like `arn:aws:s3:::bucket/path/*`.

---

## 6) Ownership: What lives where

**Terraform owns:**

* S3 bucket creation
* Bucket CORS rules
* Public access blocks
* IAM Policies for auth/admin
* IAM Role Policy Attachments (to Amplify/Cognito-created roles)

**Amplify/Cognito owns:**

* User Pool (users, groups — including `admin` group)
* Identity Pool (role mapping unauth vs auth)
* Frontend authentication flows

**App code (`backend.ts`):**

* Emits storage metadata (bucket name, region, logical path model) for the UI
* **No longer** creates/attaches S3 IAM policies or CORS

---

## 6) Terraform Project Layout

### 6.1 `terraform.tfvars` example

```hcl
bucket_name      = "loan-optimization-execution-bucket"
region           = "eu-west-1"
auth_role_name   = "amplify-APP-ENV-authRole-XXXXXXXX"
admin_role_name  = "cognito-APP-ENV-adminGroupRole-XXXXXXXX"
```

---

## 7) Discovering the role names
We need the ` auth_role_name` and `admin_role_name` which are created bty Amplify/Cognito, these need to go in our terraform variables so we can attach the policies to these user roles
### AWS Console (quickest)

1. **Identity Pool roles (auth):** Cognito → Federated identities → your pool → *IAM roles* tab → copy role names
2. **Admin group role:** Cognito → User pools → your pool → Users and groups → `admin` → if `RoleArn` exists, use that role name (else consider creating/associating one)

