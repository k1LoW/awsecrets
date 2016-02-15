require 'spec_helper'

describe Awsecrets do
  let(:fixtures_path) do
    File.expand_path(File.join(File.dirname(__FILE__), 'fixtures'))
  end

  before(:each) do
    stub_const('ENV', {})
    AWSConfig.config_file = File.expand_path(File.join(fixtures_path, '.aws', 'config'))
    allow(Dir).to receive(:home).and_return(fixtures_path)
  end

  it 'has a version number' do
    expect(Awsecrets::VERSION).not_to be nil
  end

  it '--profile option' do
    Awsecrets.load(profile: 'dev')
    expect(Aws.config[:region]).to eq('ap-northeast-1')
    expect(Aws.config[:credentials].credentials.access_key_id).to eq('DEV_ACCESS_KEY_ID')
    expect(Aws.config[:credentials].credentials.secret_access_key).to eq('DEV_SECRET_ACCESS_KEY')
  end

  it 'export AWS_PROIFLE' do
    stub_const('ENV', { 'AWS_PROFILE' => 'dev' })
    Awsecrets.load(profile: nil)
    expect(Aws.config[:region]).to eq('ap-northeast-1')
    expect(Aws.config[:credentials].credentials.access_key_id).to eq('DEV_ACCESS_KEY_ID')
    expect(Aws.config[:credentials].credentials.secret_access_key).to eq('DEV_SECRET_ACCESS_KEY')
  end

  it 'secrets.yml' do
    Awsecrets.load(profile: nil, secrets_path: File.expand_path(File.join(fixtures_path, 'secrets.yml')))
    expect(Aws.config[:region]).to eq('ap-northeast-1')
    expect(Aws.config[:credentials].credentials.access_key_id).to eq('YAML_ACCESS_KEY_ID')
    expect(Aws.config[:credentials].credentials.secret_access_key).to eq('YAML_SECRET_ACCESS_KEY')
  end
end
