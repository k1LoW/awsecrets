# awsecrets [![Gem](https://img.shields.io/gem/v/awsecrets.svg)](https://rubygems.org/gems/awsecrets) [![Travis](https://img.shields.io/travis/k1LoW/awsecrets.svg)](https://travis-ci.org/k1LoW/awsecrets)

AWS credentials loader

## awsecrets config precedence

1. Command Line Options
2. Environment Variables
3. YAML file (secrets.yml)
4. The AWS credentials file
5. The CLI configuration file

(See http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#config-settings-and-precedence)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'awsecrets'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install awsecrets

## Usage example

```ruby
require 'thor'
require 'awsecrets'

class MyAwsCLI < Thor
  class_option :profile
  class_option :region

  desc "Find EC2 by Instance ID", "Find EC2 by Instance ID"
  def find_instance_by_id(id)
    Awsecrets.load(profile: options[:profile], region: options[:region])
    ec2_client = Aws::EC2::Client.new
    ec2_client.describe_instances({
                                    instance_ids: [id]
                                  })
  end
end

MyAwsCLI.start(ARGV)
```

## Contributing

1. Fork it ( https://github.com/k1LoW/awsecrets/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
