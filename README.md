# Webhook Listener
Terraform to deploy in AWS a Webhook listener. It outputs two URLs
1. a webhook listener URL 
2. a URL to retrieve the events

# How it works

![overview](./overview.png?raw=true "overview")

## Configure
Set-up in the `variables` file the name of the bucket to create to store the events.


## Deploy

```bash
    AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY AWS_SECRET_ACCESS_KEY=YOUR_SECRET_KEY terraform apply
```