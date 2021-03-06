# IBM::Bluemix::ServiceDiscovery

[![Gem Version](https://badge.fury.io/rb/ibm-bluemix-service_discovery.svg)](https://badge.fury.io/rb/ibm-bluemix-service_discovery)

This is a Ruby Gem for interfacing with the IBM Bluemix [Service Discovery service](https://console.ng.bluemix.net/catalog/services/service-discovery/).  

This Gem provides an easy to user interface to access all of the features of
Service Discovery including:

* registration
* heartbeat
* deletion
* listing
* discovery

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ibm-bluemix-service_discovery'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ibm-bluemix-service_discovery

## Usage

### Ruby on Rails

* create an initializer, load AUTH_TOKEN from secrets
* make some config file ?
* somehow set the heartbeat frequency
* set the service name and parameters
* where to get the host and port?

### Sinatra

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `AUTH_TOKEN='your service discovery token' rake spec` to run the tests, where the AUTH_TOKEN is a valid, working auth_token for a Service Discovery instance. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/krsyoung/ibm-bluemix-service_discovery. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
