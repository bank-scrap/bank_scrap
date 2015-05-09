require 'bank_scrap/version'

module BankScrap
  autoload :VERSION, 'bank_scrap/version'
  autoload :Account, 'bank_scrap/account'
  autoload :Transaction, 'bank_scrap/transaction'
  autoload :Utils, 'bank_scrap/utils'
  autoload :HttpClient, 'bank_scrap/http_client'

  module Core
    autoload :VERSION, 'bank_scrap/core/version'
  end

  class << self
    def default_http_client
      BankScrap::HttpClient
    end

    def http_client
      @http_client || default_http_client
    end

    def http_client=(client)
      @http_client = client
    end
  end
end
