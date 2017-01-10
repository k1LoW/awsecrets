require 'awsecrets/version'
require 'optparse'
require 'aws-sdk'
require 'aws_config'
require 'yaml'

module Awsecrets
  def self.load(profile: nil, region: nil, secrets_path: 'secrets.yml')
    @profile = profile
    @region = region
    @secrets_path = secrets_path
    @credentials = @access_key_id = @secret_access_key = @session_token = @role_arn = @source_profile = nil

    # 1. Command Line Options
    load_options if load_method_args
    # 2. Environment Variables
    load_env
    # 3. YAML file (secrets.yml)
    load_yaml
    # 4. The AWS credentials file
    load_creds
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
    return unless @profile
    @region ||= AWSConfig[@profile]['region']
  end

  def self.load_env
    @region ||= ENV['AWS_REGION']
    @region ||= ENV['AWS_DEFAULT_REGION']
    @profile ||= ENV['AWS_PROFILE']
    return if @access_key_id
    return unless ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
    @access_key_id ||= ENV['AWS_ACCESS_KEY_ID']
    @secret_access_key ||= ENV['AWS_SECRET_ACCESS_KEY']
    @session_token ||= ENV['AWS_SESSION_TOKEN']
  end

  def self.load_yaml
    creds = YAML.load_file(@secrets_path) if File.exist?(@secrets_path)
    @region ||= creds['region'] if creds && creds.include?('region')
    return if @access_key_id
    return unless creds &&
                  creds.include?('aws_access_key_id') &&
                  creds.include?('aws_secret_access_key')
    @access_key_id ||= creds['aws_access_key_id']
    @secret_access_key ||= creds['aws_secret_access_key']
    @session_token ||= creds['aws_session_token'] if creds.include?('aws_session_token')
    @role_arn ||= creds['role_arn'] if creds.include?('role_arn')
    @role_session_name ||= creds['role_session_name'] if creds.include?('role_session_name')
    return unless @role_arn && @role_session_name
    @credentials ||= Aws::AssumeRoleCredentials.new(
      client: Aws::STS::Client.new(
        region: @region,
        credentials: Aws::SharedCredentials.new(
          region: @region,
          access_key_id: @access_key_id,
          secret_access_key: @secret_access_key
        )
      ),
      role_arn: @role_arn,
      role_session_name: @role_session_name
    )
  end

  def self.load_creds
  end

  def self.load_config
    @region ||= if AWSConfig[@profile] && AWSConfig[@profile]['region']
                  AWSConfig[@profile]['region']
                else
                  AWSConfig['default']['region']
                end

    @role_arn ||= AWSConfig[@profile]['role_arn'] if AWSConfig[@profile]
    @role_session_name ||= AWSConfig[@profile]['role_session_name'] if AWSConfig[@profile]
    @source_profile ||= AWSConfig[@profile]['source_profile'] if AWSConfig[@profile]
  end

  def self.set_aws_config
    Aws.config[:region] = @region

    if @role_arn && @role_session_name && @source_profile
      region = if AWSConfig[@source_profile.name] && AWSConfig[@source_profile.name]['region']
                 AWSConfig[@source_profile.name]['region']
               else
                 AWSConfig['default']['region']
               end

      @credentials ||= Aws::AssumeRoleCredentials.new(
        client: Aws::STS::Client.new(
          region: region,
          credentials: Aws::SharedCredentials.new(profile_name: @source_profile.name)
        ),
        role_arn: @role_arn,
        role_session_name: @role_session_name
      )
    end

    @credentials ||= Aws::SharedCredentials.new(profile_name: @profile) if @profile
    @credentials ||= Aws::SharedCredentials.new(profile_name: 'default') unless @access_key_id
    @credentials ||= Aws::Credentials.new(@access_key_id, @secret_access_key, @session_token)

    Aws.config[:credentials] = @credentials
  end
end
