require_relative 'awsecrets/version'
require_relative 'awsecrets/utils'
require 'optparse'
require 'aws-sdk'
require 'aws_config'
require 'yaml'

module Awsecrets
  include Misc

  def self.load(profile: nil, region: nil, secrets_path: nil, disable_load_secrets: false)
    @profile              = profile
    @region               = region
    @secrets_path         = secrets_path
    @disable_load_secrets = disable_load_secrets
    @disable_load_secrets = true if secrets_path == false

    @credentials = @access_key_id = @secret_access_key = @session_token = nil
    @role_arn = @external_id = @source_profile = @role_session_name = nil

    # 1. Command Line Options
    load_options if load_method_args
    # 2. Environment Variables
    load_env
    # 3. YAML file (secrets.yml)
    load_yaml
    # 4. The AWS credentials file
    # load_creds
    # 5. The CLI configuration file
    load_config

    set_aws_config
  end

  def self.load_method_args
    return false unless @profile
    @region ||= AWSConfig[@profile]['region'] if AWSConfig[@profile]['region']
    true
  end

  def self.load_options
    opt = OptionParser.new
    opt.on('--profile PROFILE') { |v| @profile ||= v }
    opt.on('--region REGION') { |v| @region ||= v }
    opt.on('--secrets_path SECRETS_PATH') { |v| @secrets_path ||= v }
    begin
      opt.parse!(ARGV)
    rescue OptionParser::InvalidOption
    end
    return true unless @profile
    @region ||= AWSConfig[@profile]['region']
    true
  end

  def self.load_env
    @region       ||= ENV['AWS_REGION']
    @region       ||= ENV['AWS_DEFAULT_REGION']
    @profile      ||= ENV['AWS_PROFILE']
    @secrets_path ||= ENV['AWS_SECRETS_PATH']
    return true if @access_key_id
    return unless ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
    @access_key_id     ||= ENV['AWS_ACCESS_KEY_ID']
    @secret_access_key ||= ENV['AWS_SECRET_ACCESS_KEY']
    @session_token     ||= ENV['AWS_SESSION_TOKEN']
    true
  end

  def self.load_yaml
    return false if @disable_load_secrets
    @secrets_path ||= 'secrets.yml'
    creds = YAML.load_file(@secrets_path) if File.exist?(File.expand_path(@secrets_path))
    @region ||= creds['region'] if creds && creds.include?('region')
    return true if @access_key_id
    return true unless creds &&
                  creds.include?('aws_access_key_id') &&
                  creds.include?('aws_secret_access_key')
    @access_key_id     ||= creds['aws_access_key_id']
    @secret_access_key ||= creds['aws_secret_access_key']
    @session_token     ||= creds['aws_session_token'] if creds.include?('aws_session_token')
    @role_arn          ||= creds['role_arn'] if creds.include?('role_arn')
    @external_id       ||= creds['external_id'] if creds.include?('external_id')
    @role_session_name ||= creds['role_session_name'] if creds.include?('role_session_name')

    return true unless @role_arn
    @role_session_name ||= Misc.generate_session_name
    @credentials ||= role_creds(
      client: Aws::STS::Client.new(
        region: @region,
        access_key_id: @access_key_id,
        secret_access_key: @secret_access_key
      ),
      role_arn: @role_arn,
      role_session_name: @role_session_name,
      external_id: @external_id
    )
    true
  end

  def self.load_config
    @region ||= if AWSConfig[@profile] && AWSConfig[@profile]['region']
                  AWSConfig[@profile]['region']
                elsif AWSConfig['default']
                  AWSConfig['default']['region']
                end

    @role_arn          ||= AWSConfig[@profile]['role_arn'] if AWSConfig[@profile]
    @role_session_name ||= AWSConfig[@profile]['role_session_name'] if AWSConfig[@profile]
    @external_id       ||= AWSConfig[@profile]['external_id'] if AWSConfig[@profile]
    @source_profile    ||= AWSConfig[@profile]['source_profile'] if AWSConfig[@profile]
  end

  def self.set_aws_config
    @region ||= self.current_region
    Aws.config[:region] = @region

    if @role_arn && @source_profile
      @role_session_name ||= Misc.generate_session_name
      region = if AWSConfig[@source_profile.name] && AWSConfig[@source_profile.name]['region']
                 AWSConfig[@source_profile.name]['region']
               else
                 AWSConfig['default']['region']
               end

      @credentials ||= role_creds(
        client: Aws::STS::Client.new(
          region: region,
          credentials: Aws::SharedCredentials.new(profile_name: @source_profile.name)
        ),
        role_arn: @role_arn,
        role_session_name: @role_session_name,
        external_id: @external_id
      )
    end

    @credentials ||= Aws::SharedCredentials.new(profile_name: @profile) if @profile
    @credentials ||= Aws::SharedCredentials.new(profile_name: 'default') if AWSConfig['default'] && !@access_key_id
    @credentials ||= Aws::Credentials.new(@access_key_id, @secret_access_key, @session_token) if @access_key_id
    @credentials ||= Aws::InstanceProfileCredentials.new

    Misc.validate_client
    Aws.config[:credentials] = @credentials
  end

  def self.role_creds(args)
    Aws::AssumeRoleCredentials.new(args)
  end
end
