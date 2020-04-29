# terraform-aws-oracle-lambda

This example demonstrates how to build a Lambda (Python) that connects to an RDS Oracle instance

## Introduction

This example demonstrates how to use build a Lambda (Python) function that can connect to RDS Oracle Instance.

## Step 0 - Create the RDS Oracle DB

## Step 1 - Configure the DB

The connection to the database is encrypted via SSL. Download the PEM certificate required [here](http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html)
Create a user on your RDS instance with username/password.

## Step 2 - Deploy the Lambda function

### 2.a Stage the layers

**Note:** This makes use of `docker` and the `amazonlinux` docker image

Navigate to the `/bin/create-layer` directory of this repo and run `make create/layer`

### 2.b Gather required information

The code depends on a few environment variables that need to match your deployed RDS instance:

- `endpoint`: somename.someuniquevalue.us-west-2.rds.amazonaws.com
- `password`: somepassword
- `my_db`: DB name
- `user`: Rds username

See the terraform module for additional required information.

### 2.c Deploy the project

This project is managed with terraform so just run the following commands:

```bash
terraform init
terraform apply
```
