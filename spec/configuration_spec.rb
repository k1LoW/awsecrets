require 'spec_helper'

# rubocop:disable Metrics/BlockLength
describe Awsecrets do
  let(:fixtures_path) do
    File.expand_path(File.join(File.dirname(__FILE__), 'fixtures'))
  end

  before(:each) do
    stub_const('ENV', {})
    Aws.config = {}
    Aws.config[:sts] = {
      stub_responses: {
        assume_role: {
          assumed_role_user: {
            arn: 'arn:aws:sts::123456789012:assumed-role/stub/Test',
            assumed_role_id: 'ARO123EXAMPLE123:Test'
          },
          credentials: {
            access_key_id: 'STS_ASSUMED_ACCESS_KEY_ID',
            expiration: Time.new(2016, 1, 6, 10, 0, 0, '+00:00'),
            secret_access_key: 'STS_ASSUMED_SECRET_ACCESS_KEY',
            session_token: 'STS_ASSUMED_SESSION_TOKEN'
          },
          packed_policy_size: 6
        }
      }
    }
    AWSConfig.config_file = File.expand_path(File.join(fixtures_path, '.aws', 'config'))
    AWSConfig.credentials_file = File.expand_path(File.join(fixtures_path, '.aws', 'credentials'))
    allow(Dir).to receive(:home).and_return(fixtures_path)
  end

  it 'has a version number' do
    expect(Awsecrets::VERSION).not_to be nil
  end

  context 'Configuration' do
    it 'load --profile option' do
      Awsecrets.load(profile: 'dev')
      expect(Aws.config[:region]).to eq('CONFIG_DEFAULT_REGION')
      expect(Aws.config[:credentials].credentials.access_key_id).to eq('CREDS_DEV_ACCESS_KEY_ID')
      expect(Aws.config[:credentials].credentials.secret_access_key).to eq('CREDS_DEV_SECRET_ACCESS_KEY')
    end

    it 'load --region option' do
      Awsecrets.load(region: 'OPTION_REGION')
      expect(Aws.config[:region]).to eq('OPTION_REGION')
      expect(Aws.config[:credentials].credentials.access_key_id).to eq('CREDS_DEFAULT_ACCESS_KEY_ID')
      expect(Aws.config[:credentials].credentials.secret_access_key).to eq('CREDS_DEFAULT_SECRET_ACCESS_KEY')
    end

    it 'load secrets.yml' do
      Awsecrets.load(secrets_path: File.expand_path(File.join(fixtures_path, 'secrets.yml')))
      expect(Aws.config[:region]).to eq('YAML-REGION')
      expect(Aws.config[:credentials].credentials.access_key_id).to eq('YAML_ACCESS_KEY_ID')
      expect(Aws.config[:credentials].credentials.secret_access_key).to eq('YAML_SECRET_ACCESS_KEY')
      expect(Aws.config[:credentials].credentials.session_token).to eq(nil)
    end

    it 'load secrets_other.yml via AWS_SECRETS_PATH' do
      stub_const('ENV', { 'AWS_SECRETS_PATH' => File.expand_path(File.join(fixtures_path, 'secrets_other.yml')) })
      Awsecrets.load
      expect(Aws.config[:region]).to eq('YAML_OTHER_REGION')
      expect(Aws.config[:credentials].credentials.access_key_id).to eq('YAML_OTHER_ACCESS_KEY_ID')
      expect(Aws.config[:credentials].credentials.secret_access_key).to eq('YAML_OTHER_SECRET_ACCESS_KEY')
      expect(Aws.config[:credentials].credentials.session_token).to eq(nil)
    end

    it 'load secrets_with_session_token.yml' do
      Awsecrets.load(secrets_path: File.expand_path(File.join(fixtures_path, 'secrets_with_session_token.yml')))
      expect(Aws.config[:region]).to eq('YAML-REGION')
      expect(Aws.config[:credentials].credentials.access_key_id).to eq('YAML_ACCESS_KEY_ID')
      expect(Aws.config[:credentials].credentials.secret_access_key).to eq('YAML_SECRET_ACCESS_KEY')
      expect(Aws.config[:credentials].credentials.session_token).to eq('YAML_SESSION_TOKEN')
    end

    it 'load AWS_PROFILE' do
      stub_const('ENV', { 'AWS_PROFILE' => 'dev' })
      Awsecrets.load
      expect(Aws.config[:region]).to eq('CONFIG_DEFAULT_REGION')
      expect(Aws.config[:credentials].credentials.access_key_id).to eq('CREDS_DEV_ACCESS_KEY_ID')
      expect(Aws.config[:credentials].credentials.secret_access_key).to eq('CREDS_DEV_SECRET_ACCESS_KEY')
    end

    it 'load AWS_DEFAULT_PROFILE' do
      stub_const('ENV', { 'AWS_DEFAULT_PROFILE' => 'default' })
      Awsecrets.load
      expect(Aws.config[:region]).to eq('CONFIG_DEFAULT_REGION')
      expect(Aws.config[:credentials].credentials.access_key_id).to eq('CREDS_DEFAULT_ACCESS_KEY_ID')
      expect(Aws.config[:credentials].credentials.secret_access_key).to eq('CREDS_DEFAULT_SECRET_ACCESS_KEY')
    end

    it 'load AWS_REGION' do
      stub_const('ENV', { 'AWS_REGION' => 'ENV_REGION' })
      Awsecrets.load
      expect(Aws.config[:region]).to eq('ENV_REGION')
      expect(Aws.config[:credentials].credentials.access_key_id).to eq('CREDS_DEFAULT_ACCESS_KEY_ID')
      expect(Aws.config[:credentials].credentials.secret_access_key).to eq('CREDS_DEFAULT_SECRET_ACCESS_KEY')
    end

    it 'load AWS_DEFAULT_REGION' do
      stub_const('ENV', { 'AWS_DEFAULT_REGION' => 'ENV_DEFAULT_REGION' })
      Awsecrets.load
      expect(Aws.config[:region]).to eq('ENV_DEFAULT_REGION')
      expect(Aws.config[:credentials].credentials.access_key_id).to eq('CREDS_DEFAULT_ACCESS_KEY_ID')
      expect(Aws.config[:credentials].credentials.secret_access_key).to eq('CREDS_DEFAULT_SECRET_ACCESS_KEY')
    end

    it 'load AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY' do
      stub_const('ENV', {
                   'AWS_ACCESS_KEY_ID' => 'ENV_ACCESS_KEY_ID',
                   'AWS_SECRET_ACCESS_KEY' => 'ENV_SECRET_ACCESS_KEY'
                 })
      Awsecrets.load
      expect(Aws.config[:region]).to eq('CONFIG_DEFAULT_REGION')
      expect(Aws.config[:credentials].credentials.access_key_id).to eq('ENV_ACCESS_KEY_ID')
      expect(Aws.config[:credentials].credentials.secret_access_key).to eq('ENV_SECRET_ACCESS_KEY')
      expect(Aws.config[:credentials].credentials.session_token).to be_nil
    end

    it 'load AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN' do
      stub_const('ENV', {
                   'AWS_ACCESS_KEY_ID' => 'ENV_ACCESS_KEY_ID',
                   'AWS_SECRET_ACCESS_KEY' => 'ENV_SECRET_ACCESS_KEY',
                   'AWS_SESSION_TOKEN' => 'ENV_SESSION_TOKEN'
                 })
      Awsecrets.load
      expect(Aws.config[:region]).to eq('CONFIG_DEFAULT_REGION')
      expect(Aws.config[:credentials].credentials.access_key_id).to eq('ENV_ACCESS_KEY_ID')
      expect(Aws.config[:credentials].credentials.secret_access_key).to eq('ENV_SECRET_ACCESS_KEY')
      expect(Aws.config[:credentials].credentials.session_token).to eq('ENV_SESSION_TOKEN')
    end

    context 'AssumeRole' do
      before :each do
        allow(subject).to receive(:role_creds) do |args|
          @caller_options = args
          Aws::AssumeRoleCredentials.new(args)
        end
      end

      context 'when passing --profile assumed' do
        before :each do
          Awsecrets.load(profile: 'assumed')
        end

        it 'should create the proper config' do
          expect(Aws.config[:region]).to eq('CONFIG-ASSUME-TEST-REGION')
          expect(Aws.config[:credentials].credentials.access_key_id).to eq('STS_ASSUMED_ACCESS_KEY_ID')
          expect(Aws.config[:credentials].credentials.secret_access_key).to eq('STS_ASSUMED_SECRET_ACCESS_KEY')
        end

        it 'should call Aws::AssumeRoleCredentials.new with the correct client' do
          expect(@caller_options[:client]).to be_a_kind_of(Aws::STS::Client)
        end
        it 'should call Aws::AssumeRoleCredentials.new with the correct role_arn' do
          expect(@caller_options[:role_arn]).to eq('CONFIG_ASSUMED_ROLE_ARN')
        end
        it 'should call Aws::AssumeRoleCredentials.new with the correct role_session_name' do
          expect(@caller_options[:role_session_name]).to eq('CONFIG_ASSUMED_ROLE_SESSION_NAME')
        end
        it 'should call Aws::AssumeRoleCredentials.new with the correct external_id' do
          expect(@caller_options[:external_id]).to eq('CONFIG_ASSUMED_ROLE_EXTERNAL_ID')
        end
      end

      context 'load AWS_PROFILE=assumed' do
        before :each do
          stub_const('ENV', { 'AWS_PROFILE' => 'assumed' })
          Awsecrets.load
        end

        it 'should create the proper config' do
          expect(Aws.config[:region]).to eq('CONFIG-ASSUME-TEST-REGION')
          expect(Aws.config[:credentials].credentials.access_key_id).to eq('STS_ASSUMED_ACCESS_KEY_ID')
          expect(Aws.config[:credentials].credentials.secret_access_key).to eq('STS_ASSUMED_SECRET_ACCESS_KEY')
        end

        it 'should call Aws::AssumeRoleCredentials.new with the correct client' do
          expect(@caller_options[:client]).to be_a_kind_of(Aws::STS::Client)
        end
        it 'should call Aws::AssumeRoleCredentials.new with the correct role_arn' do
          expect(@caller_options[:role_arn]).to eq('CONFIG_ASSUMED_ROLE_ARN')
        end
        it 'should call Aws::AssumeRoleCredentials.new with the correct role_session_name' do
          expect(@caller_options[:role_session_name]).to eq('CONFIG_ASSUMED_ROLE_SESSION_NAME')
        end
        it 'should call Aws::AssumeRoleCredentials.new with the correct external_id' do
          expect(@caller_options[:external_id]).to eq('CONFIG_ASSUMED_ROLE_EXTERNAL_ID')
        end
      end

      it 'load AWS_PROFILE=assumed_no_session_name' do
        stub_const('ENV', { 'AWS_PROFILE' => 'assumed_no_session_name' })
        Awsecrets.load
        expect(Aws.config[:region]).to eq('CONFIG-ASSUME-TEST-REGION')
        expect(Aws.config[:credentials].credentials.access_key_id).to eq('STS_ASSUMED_ACCESS_KEY_ID')
        expect(Aws.config[:credentials].credentials.secret_access_key).to eq('STS_ASSUMED_SECRET_ACCESS_KEY')
      end

      it 'load secrets_with_role_arn.yml' do
        Awsecrets.load(secrets_path: File.expand_path(File.join(fixtures_path, 'secrets_with_role_arn.yml')))
        expect(Aws.config[:region]).to eq('YAML-REGION')
        expect(Aws.config[:credentials].credentials.access_key_id).to eq('STS_ASSUMED_ACCESS_KEY_ID')
        expect(Aws.config[:credentials].credentials.secret_access_key).to eq('STS_ASSUMED_SECRET_ACCESS_KEY')
      end
    end
  end
end
