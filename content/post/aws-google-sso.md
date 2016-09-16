+++
date = "2016-09-16T16:19:59-04:00"
title = "aws google sso"
author = "Richard Genthner"
comments = true
draft = false
image = ""
menu = ""
share = true
slug = "aws-google-sso"
tags = ["sso", "technology", "saml", "aws", "google"]
+++

This article contains the files needed to wire up our Google Apps SSO to aws. Enorder to setup the AWS sso in additional accounts you will need the following tools:

- Aws Account keys with Admin access
- Google Admin access
- aws cli tools

## Setup Google Apps
First we will need to setup a Custom Schema element to hold role information for our users. By default, when you map attributes for SAML apps the pass Role to AWS you'll only be able to select from existing attribute on your users.
Examples include Job Title, Cost Center and Department. I've seen other articles that mention putting a signle role ARN in one of these but it's really not suitable for that information (especially if you use those fields already).

#### The Solution is to setup a [Custom Attribute](https://support.google.com/a/answer/6327792?hl=en) for your users.
* Open the [Schema Insert Page](https://developers.google.com/admin-sdk/directory/v1/reference/schemas/insert#try-it) in Google Admin Console
* Enter `my_customer` in `customerId`
* To the right of the Request Body, select `FreeForm Editor` from the dropdown list and then pase the following (schemaName should be either SSO or AWS_SAML):

```
{
  "fields":
  [
    {
      "fieldName": "role",
      "fieldType": "STRING",
      "multiValued": true,
      "readAccessType": "ADMINS_AND_SELF"
    }
  ],
  "schemaName": "SSO",
}
```

* Then Click `Authorize and Execute`

#### Setup the Google Apps SAML App for AWS
You'll need to configure your Google Apps account as a identity provider (or IdP) for AWS to use.

Google has written some pretty good instructions for this [here](https://support.google.com/a/answer/6194963?hl=en). Go check them out and run though them then come back here or follow my brief instructions below:

1. Login into your Google Apps Admin Console
2. Head to the `Apps` Section then `SAML Apps`
3. Click `Add a Service/App to your domain`
4. Select `Amazon Web Services`
5. Click the `Download` button next to the `IDP Metadata` and save it somewhere for later
6. If you want to change the Application Name, Description and Logo, otherwise continue on
7. Setup the Service Provider Details
8. Make sure the `ACS URL` and `Entity ID` are set to `https://signin.aws.amazon.com/saml`
9. Also make sure the `Start URL` is blank and the `Signed Response` is unchecked.
10. You'll want the `Name ID` to be mapped to `Basic information: Primary Email`
11. Set the Attribute mapping up with the following:
12. `https://aws.amazon.com/SAML/RoleSessionName: Basic Information: Primary Email`
13. `https://aws.amazon.com/SAML/Role : SSO : Role`
14. Click Finish
15. Turn the App on, by clicking on the settings button, then `Turn ON for everyone` Confirm the dialong when asked


## Setting up the IdP in AWS
You'll need to tell AWS that you want to use the GoogleApp you just set up as a IdP.
You can do that with the command below:

```
# aws iam create-saml-provider --saml-metadata-document file://GoogleIDPMetadata-yourdomain.xml --name GoogleAppsProvider
{
    "SAMLProviderArn": "arn:aws:iam::123456789012:saml-provider/GoogleAppsProvider"
}
```
Make sure you substitute `GoogleIDPMetadata-yourdomain.xml` with the path to the IDP metadata file you downloaded earlier.

This will spit out a response with the ARN of the identity provider you created, so make sure you note this down for later.

####Create Some Roles
1. You'll need to first craft a Trust Policy document to be used with the roles you'll create. Create a new file called `GoogleApps_TrustPolicy.json` with the following contents:

```
{
  "Version": "2012-10-17",
  "Statement": [
  {
    "Effect": "Allow",
    "Principal": {
      "Federated": "<Replace Me with your IdP ARN>"
    },
    "Action": "sts:AssumeRoleWithSAML",
    "Condition": {
      "StringEquals": {
        "SAML:aud": "https://signin.aws.amazon.com/saml"
      }
    }
  }
  ]
}
```
Make sure you replace `<Replace Me with your IdP ARN>` with the ARN of the identity provider you created earlier.

1. Run the following command to create the role. Note down the ARN that is returned as we'll need it later

```
# aws iam create-role --role-name GoogleAppsAdminDemo --assume-role-policy-document file://GoogleApps_TrustPolicy.json
{
  "Role": {
  "AssumeRolePolicyDocument": {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Action": "sts:AssumeRoleWithSAML",
              "Effect": "Allow",
              "Condition": {
                  "StringEquals": {
                      "SAML:aud": "https://signin.aws.amazon.com/saml"
                  }
              },
              "Principal": {
                  "Federated": "arn:aws:iam::123456789012:saml-provider/GoogleAppsProvider"
              }
          }
      ]
  },
  "RoleId": "AROAIYGHGSVXXXXXXXXXX",
  "CreateDate": "2016-03-10T12:19:31.177Z",
  "RoleName": "GoogleAppsAdminDemo",
  "Path": "/",
  "Arn": "arn:aws:iam::123456789012:role/GoogleAppsAdminDemo"
  }

```

2. At this stage, I've not attached any permissions to the role - you can read how to do that [here](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_manage_modify.html#d0e18315)


### Add some roles to your Google Apps Users
1. Open the [Patch Users Page](https://developers.google.com/admin-sdk/directory/v1/reference/users/patch#try-it) in the Google Admin Console
2. In the `userKey` put the email address of the user you want to update
3. To the right of the Request body, select `Freeform Editor` from the drop down list, and paste the following text, replace, and with the appropriate values you've collected before

```
{
  "customSchemas":
  {
    "SSO":
    {
      "role": [
      {
       value: "<role ARN>,<provider ARN>",
       customType: "SSO"
      }
     ]
    }
  }
}

```

Mine looked something like this (with two roles):

```
{
  "customSchemas":
  {
    "SSO":
    {
      "role": [
      {
       value: "arn:aws:iam::123456789012:role/GoogleAppsAdminDemo,arn:aws:iam::123456789012:saml-provider/GoogleAppsProvider,
       customType: "SSO"
      },
      {
       value: "arn:aws:iam::123456789012:role/GoogleAppsUserDemo,arn:aws:iam::123456789012:saml-provider/GoogleAppsProvider,
       customType: "SSO"
      }
     ]
    }
  }
}
```
4. Click `Authorize and Execute`

### Test it out
Open your Google Apps account and then select the `Amazon Web Services` app. It should redirect you on to a page that lets you select Role to login with (only if you multiple Roles) otherwise it will just bring you to the AWS Console Homepage.
