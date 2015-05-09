# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = 'bank_scrap-bbva'
  spec.version       = BankScrap::VERSION
  spec.authors       = ['Your Name']
  spec.email         = ['email@example.com']
  spec.summary       = %q{BankScrap bbva integration.}
  spec.description   = %q{bbva integration using internal mobile API.}
  spec.homepage      = 'https://github.com/bank-scrap/bank_scrap'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/bank_scrap/bbva{.rb,**/.rb}']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '~> 2.0'

  spec.add_dependency 'bank_scrap-core', '~> 0.1'
  spec.add_dependency 'bank_scrap-mechanize', '~> 0.1'
  spec.add_dependency 'money',         '~> 6.5.0'
end
