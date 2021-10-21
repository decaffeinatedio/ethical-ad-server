# About

This project takes the core Ethical Ad Server (EAS) and modifies it in order to 
a) Lend itself more easily to self-hosting (specifically on Heroku)
b) More flexibly act as an ad server in somewhat traditional publishers
c) Update branding and various EAS specifics to suit the purposes of this project. 

# Diff Overview
There are a small number of critical changes that are required to work with EAS in your environment. 
- New Dockerfile
- Updated package.json
- Extended env var configuration
- Remove some EAS-specific branding (eg. admin template)

There may be more! I am still finding issues as I operate EAS independently, so please file issues as you come across them. 

# Changes
- Edit timezone; in: `config/settings/base.py`
- Move server email to env var; in: `config/settings/base.py`
- Update geoip names in Makefile for resolution; in: `Makefile`
- Had to do some npm force cleaning to get the build to reliably work; in: `Dockerfile` 
- Note: IP2Proxy is still not working, as it required a unique download token.
- Add adblock detection pixel (https://media.ethicalads.io/abp/px.gif)
- Support multiple placements SUPPORTS_MULTIPLE_PLACEMENTS 
- Update rendered div from `ethical-ad` to `as` to avoid overzealous blockers. 

# Installation

## Prerequisites

### Sendgrid
You will need a (validated) Sendgrid API key for sending emails. Sign up here: https://signup.sendgrid.com/

Remember to go through [sender authentication](https://app.sendgrid.com/settings/sender_auth)!

### Azure
Azure is assumed as the default storage. Azure is one of the [cheaper](https://www.backblaze.com/b2/cloud-storage-pricing.html) storage solutions.

Allow public Azure blob [read-only access](https://docs.microsoft.com/en-us/azure/storage/blobs/anonymous-read-access-configure?tabs=azure-cli): 

```
az storage account create \
    --name <storage-account> \
    --resource-group <resource-group> \
    --kind StorageV2 \
    --location <location> \
    --allow-blob-public-access true

az storage account show \
    --name <storage-account> \
    --resource-group <resource-group> \
    --query allowBlobPublicAccess \
    --output tsv

az storage account update \
    --name <storage-account> \
    --resource-group <resource-group> \
    --allow-blob-public-access false
```

Retrieve your Azure account key by running:
`$ az storage account keys list -g CONTAINER -n ACCOUNT`
Note that this requires the Azure CLI. 

### Heroku
You will need a free Heroku account and the Heroku CLI. 

## Ad Server Setup

### Local Configuration
- Clone the `herokuMod` branch to your machine. 
- Run `make geoip` and `make ipproxy` to download the IP and proxy assets. 

### Heroku Configuration
- Sign in to Heroku and Heroku container registry: `heroku login`, `heroku container:login`
- Create new Heroku app: `heroku create`
- Add Redis and Postgresql: `heroku addons:create heroku-redis:hobby-dev -a APP_NAME`, `heroku addons:create heroku-postgresql:hobby-dev -a APP_NAME`
- Enable bash login: `heroku features:enable runtime-heroku-exec -a APP_NAME`
- Set env variables: 

```
heroku config:set\
    DJANGO_SETTINGS_MODULE=config.settings.production \
    SECRET_KEY= \
    SENDGRID_API_KEY= \
    ALLOWED_HOSTS=APP_NAME.herokuapp.com \
    SERVER_EMAIL= \
    NO_REPLY= \
    AZURE_ACCOUNT_KEY= \
    AZURE_ACCOUNT_NAME= \
    AZURE_CONTAINER= \
    ADSERVER_HTTPS=True \
    -a APP_NAME
```
- Run `heroku container:push web -a APP_NAME` 
- Release container `heroku container:release web -a APP_NAME`


### Finishing Up
- Validate that the release went through by checking logs: `heroku logs -a APP_NAME`
- Log in via bash `heroku run bash -a APP_NAME`
- Once logged in via bash, run required migrations to create database assets: `./manage.py migrate`. This process may take about a minute to complete. 
- Next, run `./manage.py createsuperuser` to create an admin for the ad server. 
- You should now be able to log in via the web interface. 
- Make sure you update the "site" to the domain you'd like to use in the admin page. 
- If you'd like to use a custom domain, run `heroku domains:add HOST_NAME -a APP_NAME` and then update your registrar/DNS servers to point to the DNS Target Heroku returns. Make sure you also update your `ALLOWED_HOSTS` env variable and, if needed, upgrade to a Hobby dyno (`heroku ps:resize web=hobby -a APP_NAME`) to enable TLS/SSL via Heroku's ACM. 

## Troubleshooting

If you don't run manage.py manually, you may need to use https://tools.heroku.support/limits/boot_timeout