# coding: utf-8

require_relative '../bank_scrap-base'

BankScrap::Specification.new do |spec|
  spec.name          = 'bank_scrap-banc_sabadell'

  spec.authors       = ['Michal Cichra']
  spec.email         = ['michal.cichra@gmail.com']
  spec.summary       = %q{BankScrap Banc Sabadell integration.}
  spec.description   = %q{Banc Sabadell integration using internal mobile API.}

  spec.files         = Dir['lib/bank_scrap/banc_sabadell{.rb,**/.rb}']

  spec.add_dependency 'bank_scrap-core', '~> 0.1'
  spec.add_dependency 'bank_scrap-mechanize', '~> 0.1'
end

