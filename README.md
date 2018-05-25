# Soapforce

_**PLEASE NOTE:** README.md modified to match changes in this Forked repo, if a PR is made to original Tinderbox repo some changes will need to be reverted to match that repo_

Soapforce is a ruby gem for the [Salesforce SOAP API](http://www.salesforce.com/us/developer/docs/api/index.htm).
This gem was modeled after the [restforce](https://github.com/ejholmes/restforce) gem and depends on [Savon 2](http://savonrb.com/version2/).

## Installation

Add this line to your application's Gemfile (getting the latest changes from the source):

    gem 'soapforce', git: "git://github.com/skplunkerin/soapforce-v41.git", branch: "master"

And then execute:

    $ bundle install

## Usage

For ISV Partners you can specify your client_id in a configuration block which will get included in the CallOptions header of every request.

    # config/initializers/soapforce.rb
    # This is your ISV Partner Client ID.
    # It needs to be whitelisted to enable SOAP requests in Professional and Group Editions.
    Soapforce.configure do |config|
      config.client_id     = "ParterName/SomeValue/"
    end

### Sandbox Orgs

You can connect to sandbox orgs by specifying a host. The default host is 'login.salesforce.com':

```ruby
client = Soapforce::Client.new(host: 'test.salesforce.com')
```

### Logging

You can specify a logger by passing a logger. Logging is disabled by default.

```ruby
client = Soapforce::Client.new(logger: Logger.new(STDOUT))
```

#### Username/Password authentication

If you prefer to use a username and password to authenticate:

```ruby
client = Soapforce::Client.new
client.authenticate(username: 'foo', password: 'password_and_security_token')
```

#### Session authentication

```ruby
client = Soapforce::Client.new
client.authenticate(session_id: 'session id', server_url: 'server url')
```

### find

```ruby
client.find('Account', '006A000000Lbiiz')
# => #<Soapforce::SObject Id="006A000000Lbiiz" Name="Test" LastModifiedBy="005G0000003f1ABPIN" ... >

client.find('Account', '1234', 'Some_External_Id_Field__c')
# => #<Soapforce::SObject Id="006A000000Lbiiz" Name="Test" LastModifiedBy="005G0000003f1ABPIN" ... >
```

### find_where

```ruby
client.find_where('Account', Name: "Test")
# => [#<Soapforce::SObject Id="006A000000Lbiiz" Name="Test" LastModifiedBy="005G0000003f1ABPIN" ... >]

client.find_where('Account', Some_External_Id_Field__c: 1, ["Id", "Name, "CreatedBy"])
# => [#<Soapforce::SObject Id="006A000000Lbiiz" Name="Test" CreatedBy="005G0000003f1ABPIN" ... >]
```

### search

```ruby
# Find all occurrences of 'bar'
client.search('FIND {bar}')
# => #[<Hash>]
```

### create

```ruby
# Add a new account
client.create('Account', Name: 'Foobar Inc.')
# => {id: '006A000000Lbiiz', success: true}
```

### update

```ruby
# Update the Account with Id '006A000000Lbiiz'
client.update('Account', Id: '006A000000Lbiiz', Name: 'Whizbang Corp')
# => {id: '006A000000Lbiiz', success: true}
```

```ruby
# Update the Account with Id '006A000000Lbiiz' using <AllOrNoneHeader>
client.update('Account', {Id: '006A000000Lbiiz', Name: 'Whizbang Corp'}, {AllOrNoneHeader: {allOrNone: 'true'}})
# => {id: '006A000000Lbiiz', success: true}
```

### upsert

```ruby
# Update the record with external ID of 12
client.upsert('Account', 'External__c', External__c: 12, Name: 'Foobar')
# => {id: '006A000000Lbiiz', success: true, created: false}
```

### destroy

```ruby
# Delete the Account with Id '006A000000Lbiiz'
client.destroy('006A000000Lbiiz')
# => {id: '0016000000MRatd', success: true}
```

### convert lead

```ruby
# Convert single Lead to an Opportunity
client.convert_lead(leadId: '00Qi000001bMOu0', opportunityName: 'Opportunity from Lead', convertedStatus: 'Closed - Converted')
# => {account_id: '001i0000025uoFQAAY', contact_id: '003i000004Oow8eAAB', lead_id: '00Qi000001bMOu0EAG', opportunity_id: '006i000000hzfzaAAA', success: true}
```

```ruby
# Convert multiples Leads to Opportunities
client.convert_lead([
  {leadId: '00Qi000001bMOuy', convertedStatus: 'Closed - Converted'},
  {leadId: '00Qi000001bMOuo', convertedStatus: 'Closed - Converted'}
])
# => [
#  {account_id: '001i0000025uoJHAAY', contact_id: '003i000004Op3ZeAAJ', lead_id: '00Qi000001bMOuyEAG', opportunity_id: '006i000000hzg0EAAQ', success: true},
#  {account_id: '001i0000025uoJIAAY', contact_id: '003i000004Op3ZfAAJ', lead_id: '00Qi000001bMOuoEAG', opportunity_id: '006i000000hzg0FAAQ', success: true}
# ]
```

### describe

```ruby
# get the global describe for all sobjects
client.describe_global
# => { ... }

# get the describe for the Account object
client.describe('Account')
# => { ... }

# get the describe for Account and Opportunity object
client.describe(['Account', 'Opportunity'])
# => [{ ... },{ ... }]
```

### describe_layout

```ruby
# get layouts for an sobject type
client.describe_layout('Account')
# => { ... }

# get the details for a specific layout
client.describe_layout('Account', '012000000000000AAA')
# => { ... }
```

### logout

```ruby
client.logout
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
