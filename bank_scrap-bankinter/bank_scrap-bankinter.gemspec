# coding: utf-8

require_relative '../bank_scrap-base'

BankScrap::Specification.new do |spec|
  spec.name          = 'bank_scrap-bankinter'

  spec.authors       = ['Your Name']
  spec.email         = ['email@example.com']
  spec.summary       = %q{BankScrap Bankinter integration.}
  spec.description   = %q{Bankinter integration using internal mobile API.}

  spec.files         = Dir['lib/bank_scrap/banks/bankinter{.rb,**/.rb}']

  spec.add_dependency 'bank_scrap-core', '~> 0.1'
  spec.add_dependency 'nokogiri',      '~> 1.6'
  spec.add_dependency 'execjs',        '~> 2.2'
  spec.add_dependency 'bank_scrap-mechanize', '~> 0.1'
end
