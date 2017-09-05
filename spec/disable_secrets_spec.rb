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

  context 'Disable load YAML' do
    it 'secrets_path: false' do
      stub_const('ENV', { 'AWS_SECRETS_PATH' => File.expand_path(File.join(fixtures_path, 'secrets.yml')) })
      Awsecrets.load(secrets_path: false)
      expect(Aws.config[:region]).to eq('CONFIG_DEFAULT_REGION')
      expect(Aws.config[:credentials].credentials.access_key_id).to eq('CREDS_DEFAULT_ACCESS_KEY_ID')
      expect(Aws.config[:credentials].credentials.secret_access_key).to eq('CREDS_DEFAULT_SECRET_ACCESS_KEY')
    end
  end

  context 'Disable load YAML' do
    it 'disable_load_secrets: true' do
      stub_const('ENV', { 'AWS_SECRETS_PATH' => File.expand_path(File.join(fixtures_path, 'secrets.yml')) })
      Awsecrets.load(disable_load_secrets: true)
      expect(Aws.config[:region]).to eq('CONFIG_DEFAULT_REGION')
      expect(Aws.config[:credentials].credentials.access_key_id).to eq('CREDS_DEFAULT_ACCESS_KEY_ID')
      expect(Aws.config[:credentials].credentials.secret_access_key).to eq('CREDS_DEFAULT_SECRET_ACCESS_KEY')
    end
  end
end
