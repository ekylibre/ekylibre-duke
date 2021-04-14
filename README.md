# Duke

Gem to import Duke methods and webchat for an Ekylibre farm.
Duke currently handles harvest receptions (viti) and vegetal/viti interventions

## Installation

Add this line to your application's Gemfile:

```
gem 'duke', gitlab: 'ekylibre/ekylibre-duke', branch: 'master'
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
```
ekylibre-duke/skills/(ekylibre || ekyviti)/skill.json
```

## Azure Cloud (STT)

Create a new cognitive resource & enable Speech services & store keys

## Pusher

Create a new pusher app (Ruby backend / JS frontend) & store keys

## Ensure your environments variables are defined

Ekylibre uses dotenv locally. 
```
$ touch .env  (at the root of your ekylibre clone)
```
Add following environment variables 
```
WATSON_APIKEY=YOUR_WATSON_API_KEY
WATSON_URL=YOUR_WATSON_URL
WATSON_VERSION=YOUR_WATSON_VERSION
WATSON_EKYVITI_ID=YOUR_ASSISTANT_ID
WATSON_EKY_ID=YOUR_ASSISTANT_ID
PUSHER_APP_ID=YOUR_PUSHER_ID
PUSHER_KEY=YOUR_PUSHER_KEY
PUSHER_SECRET=YOUR_PUSHER_SECRET
PUSHER_CLUSTER=YOUR_PUSHER_CLUSTER
AZURE_API_KEY=YOUR_AZURE_API_KEY
AZURE_REGION=YOUR_AZURE_REGION
```
4. Redirect your IBM webhooks requests to your ekylibre server 

Locally : 

Install ngrok & execute below command:
```
$ ./ngrok http -host-header=TENANT.ekylibre.lan PORT
```
Go to your Watson Assistant, in options/webhooks & set your webhook url to 
```
https://your_forwarding.ngrok.io/dukewatson
```
On server :
```
https://demo.server.farm/dukewatson
```

## Usage

Full documentation can be found here : [Confluance Ekylibre-duke documentation](https://ekylibre.atlassian.net/wiki/spaces/EKYLIBRE/pages/262536/Installation+-+Duke)

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub in [this repository](https://gitlab.com/ekylibre/ekylibre-duke)
