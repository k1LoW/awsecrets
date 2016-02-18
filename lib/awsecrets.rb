require 'awsecrets/version'
require 'optparse'
require 'aws-sdk'
require 'aws_config'
require 'yaml'

module Awsecrets
  def self.load(profile: nil, region: nil, secrets_path: 'secrets.yml')
    @profile = profile
    @secrets_path = secrets_path
    @region = region
    @credentials = nil

    load_method_args
    # 1. Command Line Options
    load_options
    # 2. Environment Variables
    load_env
    # 3. YAML file (secrets.yml)
    load_yaml
    # 4. The AWS credentials file
    load_creds
    # 5. The CLI configuration file
    load_config

    Aws.config[:region] = @region
    Aws.config[:credentials] = @credentials
  end

  def self.load_method_args
    return unless @profile
    aws_config = AWSConfig.profiles[@profile]
    @region = aws_config.config_hash[:region] if aws_config && @region.nil?
    @credentials = Aws::SharedCredentials.new(profile_name: @profile)
  end

  def self.load_options
    opt = OptionParser.new
    opt.on('--profile PROFILE') { |v| @profile = v } unless @profile
    opt.on('--region REGION') { |v| @region = v } unless @region
    opt.parse!(ARGV)
    return unless @profile
    aws_config = AWSConfig.profiles[@profile]
    @region = aws_config.config_hash[:region] if aws_config && @region.nil?
    @credentials = Aws::SharedCredentials.new(profile_name: @profile)
    @credentials = Aws::SharedCredentials.new(profile_name: @profile)
  end

  def self.load_env
    @region = ENV['AWS_REGION'] unless @region
    @region = ENV['AWS_DEFAULT_REGION'] unless @region
    if @credentials.nil? && ENV['AWS_PROFILE']
      @credentials = Aws::SharedCredentials.new(profile_name: ENV['AWS_PROFILE'])
      @profile = ENV['AWS_PROFILE']
    end
    if @credentials.nil? && ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
      @credentials = @credentials = Aws::Credentials.new(
        ENV['AWS_ACCESS_KEY_ID'],
        ENV['AWS_SECRET_ACCESS_KEY'])
    end
  end

  def self.load_yaml
    creds = YAML.load_file(@secrets_path) if File.exist?(@secrets_path)
    if @region.nil? && creds
      @region = creds['region'] if creds.include?('region')
    end
    if @credentials.nil? && creds && creds.include?('aws_access_key_id') && creds.include?('aws_secret_access_key')
      @credentials = Aws::Credentials.new(
        creds['aws_access_key_id'],
        creds['aws_secret_access_key'])
    end
  end

  def self.load_creds
    return unless @credentials.nil?
    @credentials = Aws::SharedCredentials.new(profile_name: nil)
  end

  def self.load_config
    return unless @region.nil?
    aws_config = AWSConfig.profiles[@profile]
    aws_config = AWSConfig.profiles['default'] unless aws_config
    @region = aws_config.config_hash[:region] if aws_config
  end
end
