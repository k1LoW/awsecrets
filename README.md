# awsecrets [![Gem](https://img.shields.io/gem/v/awsecrets.svg)](https://rubygems.org/gems/awsecrets) [![Travis](https://img.shields.io/travis/k1LoW/awsecrets.svg)](https://travis-ci.org/k1LoW/awsecrets)

AWS credentials loader

## awsecrets config precedence

1. Command Line Options (Awscreds#load method args OR self optparse)
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

Create command line tool `ec2sample` like following code

```ruby
#!/usr/bin/env ruby
require 'awsecrets'
Awsecrets.load
ec2_client = Aws::EC2::Client.new
puts ec2_client.describe_instances({ instance_ids: [ARGV.first] }).reservations.first.instances.first
```

And execute

```sh
$ ec2sample i-1aa1aaaa --profile mycreds --region ap-northeast-1

or

$ AWS_ACCESS_KEY_ID=XXXXXXXXXXXXXXXXXXXX AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX AWS_REGION=ap-northeast-1 ec2sample i-1aa1aaaa

or

$ cat <<EOF > secrets.yml
region: ap-northeast-1
aws_access_key_id: XXXXXXXXXXXXXXXXXXXX
aws_secret_access_key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
EOF
$ ec2sample i-1aa1aaaa
```

## Contributing

1. Fork it ( https://github.com/k1LoW/awsecrets/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
