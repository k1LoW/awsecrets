require 'net/http'

module Misc
  def self.validate_client
    return unless ENV.key?('DISABLE_AWS_CLIENT_CHECK') && (ENV['DISABLE_AWS_CLIENT_CHECK'] == 'false')

    begin
      Aws::EC2::Client.new
    rescue Aws::Errors::MissingRegionError
      raise 'Missing region: use "region" command line option or export ENV[\'AWS_REGION\'] or awscli configure'
    rescue StandardError => e
      raise "Oops, there is something wrong with AWS client configuration => #{e}"
    end
  end

  def self.generate_session_name
    "awsecrets-session-#{Time.now.to_i}"
  end

  def self.current_region
    metadata_endpoint = 'http://169.254.169.254/latest/meta-data/'
    az = Net::HTTP.get(URI.parse(metadata_endpoint + 'placement/availability-zone'))
    az[0...-1]
  end
end
