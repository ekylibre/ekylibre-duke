# Duke

Gem to import Duke methods and webchat for an Ekylibre farm.
Duke currently handles harvest receptions (viti) and vegetal/viti interventions

## Installation

Add one of these line to your application's Gemfile:

```
gem 'duke', git: 'git@gitlab.com:ekylibre/ekylibre-duke.git', branch: 'dev' # for dev branch
gem 'duke', git: 'git@gitlab.com:ekylibre/ekylibre-duke.git', branch: 'master' # for prod branch
gem 'duke', path: '../ekylibre-duke' # for local dev
```
And then execute:
```
$ bundle
```
Create an account for external API uses

These steps are only to be done if you’re not part of Ekylibre developers

## IBM cloud

a. Create a new instance of Watson-Assistant & a new assistant (3 month free)

b. Clone Gitlab ekylibre-duke repo

c. On your newly created assistant, import skill from

If you change skills on IBM Watson, you have to backup all skills and save it into `ekylibre-duke.json`

```
ekylibre-duke/skills/ekylibre-duke.json
```

## Azure Cloud (STT)

Create a new cognitive resource & enable Speech services & store keys

## Local Development

1. Redirect your IBM webhooks requests to your ekylibre server

Locally :

Install ngrok & execute below command:

```
$ ./ngrok http --domain=YOUR_DOMAIN --host-header=TENANT.ekylibre.lan PORT
```

Example 1 : ./ngrok http --host-header=demo.ekylibre.lan 3000

Example 2 : ./ngrok http --host-header=entredeuxterres.ekylibre.lan 3000

Example 3 : ngrok http --domain=intimate-firefly-top.ngrok-free.app --host-header=demo.ekylibre.lan 3000

Get the https url from ngrok console as YOUR_NGROK_HTTPS_URL

2. Add environment variable 

Ekylibre uses dotenv locally.
```
$ touch .env  (at the root of your ekylibre clone)
```
Add following environment variables
```
WATSON_APIKEY=YOUR_WATSON_API_KEY
WATSON_URL=WATSON_URL
WATSON_VERSION=WATSON_API_VERSION # https://cloud.ibm.com/docs/assistant?topic=assistant-release-notes
WATSON_ID=YOUR_ASSISTANT_ID
AZURE_API_KEY=YOUR_AZURE_API_KEY
AZURE_REGION=YOUR_AZURE_REGION
NGROK_HTTPS_URL=YOUR_NGROK_HTTPS_URL
```

3. Start your server

```
$ foreman s
```

## Contributing

Bug reports and pull requests are welcome on GitHub in [this repository](https://gitlab.com/ekylibre/ekylibre-duke)
