# awsecrets [![Gem](https://img.shields.io/gem/v/awsecrets.svg)](https://rubygems.org/gems/awsecrets) [![Travis](https://img.shields.io/travis/k1LoW/awsecrets.svg)](https://travis-ci.org/k1LoW/awsecrets)

AWS credentials loader

## awsecrets config precedence

1. Command Line Options (Awscreds#load method args OR self optparse)
2. Environment Variables
3. YAML file (secrets.yml)
4. The AWS credentials file
5. The CLI configuration file
6. Instance profile credentials

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

### Generate exception with wrong configuration

For some use cases, awsecrets might raise an exception if (even after all
attempts to configure access to an AWS account) there is missing configuration
parameters.

In other cases, this might not be desired.

To have control on that, you can use the environment variable
`DISABLE_AWS_CLIENT_CHECK`: if you set it to the string `'true'`, it will not
attempt to early create an `Aws::EC2::Client` instance with the found
parameters.

By default, even if you don't set `DISABLE_AWS_CLIENT_CHECK` it will be treated
like `true`.

To enable this early checking, you **must** setup `DISABLE_AWS_CLIENT_CHECK`
with the string `'false'`.

### Basic example

Create a command line tool `ec2sample` like following code:

```ruby
#!/usr/bin/env ruby
require 'awsecrets'
Awsecrets.load
ec2_client = Aws::EC2::Client.new
puts ec2_client.describe_instances({ instance_ids: [ARGV.first] }).reservations.first.instances.first
```

Then execute it with command line parameters:

```sh
$ ec2sample i-1aa1aaaa --profile mycreds --region ap-northeast-1
```

or with environment variables configuration:

```sh
$ AWS_ACCESS_KEY_ID=XXXXXXXXXXXXXXXXXXXX AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX AWS_REGION=ap-northeast-1 ec2sample i-1aa1aaaa
```

or using an YAML file:

```sh
$ cat <<EOF > secrets.yml
region: ap-northeast-1
aws_access_key_id: XXXXXXXXXXXXXXXXXXXX
aws_secret_access_key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
EOF
$ ec2sample i-1aa1aaaa
```

### Use AssumeRole

Support `role_arn` `role_session_name` `source_profile` `external_id`.

#### 1. `.aws/config` and `.aws/credentials`

see http://docs.aws.amazon.com/cli/latest/userguide/cli-roles.html

```
# .aws/config
[profile assumed]
role_arn = arn:aws:iam::123456780912:role/assumed-role
external_id = myfoo_id
source_profile = assume_test
```

```
# .aws/credentials
[assume_test]
aws_access_key_id = XXXXXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

And execute

```sh
$ ec2sample i-1aa1aaaa --profile assumed --region ap-northeast-1
```

#### 2. `secrets.yml`

```sh
$ cat <<EOF > secrets.yml
region: ap-northeast-1
aws_access_key_id: XXXXXXXXXXXXXXXXXXXX
aws_secret_access_key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
role_arn = arn:aws:iam::123456780912:role/assumed-role
```

And execute

```sh
$ ec2sample i-1aa1aaaa
```

### Disable load YAML (`secrets.yml`)

```ruby
Awsecrets.load(disable_load_secrets:true)
```

or

```ruby
Awsecrets.load(secrets_path:false)
```

## Contributing

1. [Fork it]( https://github.com/k1LoW/awsecrets/fork ) !
2. Create your feature branch (`git checkout -b my-new-feature`).
3. Commit your changes (`git commit -am 'Add some feature'`).
4. Push to the branch (`git push origin my-new-feature`).
5. Create a new Pull Request.
