#!/usr/bin/env ruby -Ku

# App Store Connect API Ruby Client Library
#
# Allows access to the App Store Connect API using the Ruby programming language.
# This library is not affiliated with Apple, Inc. or any of its subsidiaries.
#

require 'base64'
require 'jwt'
require 'json_api_client'

require 'app_store_connect_api/testflight/apps'
require 'app_store_connect_api/testflight/beta_testers'

module AppStoreConnectAPI

  class Base < JsonApiClient::Resource
    self.site = 'https://api.appstoreconnect.apple.com/v1'
  end

  class BetaTesters < AppStoreConnectAPI::Base
    def self.table_name
      "betaTesters"
    end
  end

  class Apps < AppStoreConnectAPI::Base
  end

  class Client
    attr_accessor :token

    # Configure the client
    #
    # @example
    #   client = AppStoreConnectAPI::Client.new(issuer_id, key_id, access_key_path)
    #
    # @param issuer_id [String] the issuer id found under the users and access page in App Store Connect
    # @param key_id [String] the key id specific to the following access key
    # @param access_key [File] access key p8 file used to generate the jwt for authentication with the api
    def initialize(issuer_id, key_id, access_key)
      raise ConfigurationError, 'issuer_id is required' if issuer_id.nil?
      raise ConfigurationError, 'key_id is required' if key_id.nil?
      raise ConfigurationError, 'access_key is required' if access_key.nil?

      private_key = OpenSSL::PKey.read(access_key)
      @token = JWT.encode(
        {
          iss: issuer_id,
          exp: Time.now.to_i + 20 * 60,
          aud: 'appstoreconnect-v1'
        },
        private_key,
        'ES256',
        header_fields={
          kid: key_id
        }
      )
    end

    def headers
      { 'Authorization' => "Bearer #{@token}" }
    end

    include AppStoreConnectAPI::TestFlight::Apps
    include AppStoreConnectAPI::TestFlight::BetaTesters

  end

end