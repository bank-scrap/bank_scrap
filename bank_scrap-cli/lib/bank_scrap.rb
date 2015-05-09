require 'bank_scrap/core'

require 'active_support/all'
require 'money'
require 'bank_scrap/config'
require 'bank_scrap/cli'
require 'bank_scrap/core'

module BankScrap
  autoload :HttpClient, 'bank_scrap/http_client'
  autoload :NetHttpClient, 'bank_scrap/net_http_client'
end
