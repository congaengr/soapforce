# Soapforce


[![Build Status](https://travis-ci.org/TinderBox/soapforce.png)](https://travis-ci.org/TinderBox/soapforce)

Wrapper API for the Salesforce SOAP API based on [Savon 2](http://savonrb.com/version2/)

The API was modeled after the [restforce](https://github.com/ejholmes/restforce) gem.

## Installation

Add this line to your application's Gemfile:

    gem 'soapforce', :git => "git://github.com/TinderBox/soapforce.git"

And then execute:

    $ bundle


## Usage

For ISV Partners you can specify your client_id in a configuration block which will get included in the CallOptions header of every request.  

    # config/initializers/soapforce.rb
    # This is our ISV Partner Client ID that has been whitelisted for use in Professional and Group Editions.
    Soapforce.configure do |config|
      config.client_id     = "ParterName/SomeValue/"
    end


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
