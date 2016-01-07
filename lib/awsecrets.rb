require 'awsecrets/version'
require 'aws-sdk'
require 'aws_config'
require 'yaml'

module Awsecrets
  def self.load(profile = nil, secrets_path = 'secrets.yml')
    profile = ENV['AWS_PROFILE'] if profile.nil?
    if profile
      # SharedCredentials
      aws_config = AWSConfig.profiles[profile]
      aws_config = AWSConfig.profiles['default'] unless aws_config
      Aws.config[:region] = aws_config.config_hash[:region] if aws_config
      Aws.config[:credentials] = Aws::SharedCredentials.new(profile_name: profile)
    else
      # secrets.yml
      creds = YAML.load_file(secrets_path) if File.exist?(secrets_path)
      return if creds.nil?
      Aws.config.update({
                          region: creds['region']
                        }) if creds.include?('region')
      Aws.config.update({
                          credentials: Aws::Credentials.new(
                            creds['aws_access_key_id'],
                            creds['aws_secret_access_key'])
                        }) if creds.include?('aws_access_key_id') && creds.include?('aws_secret_access_key')
    end
  end
end
