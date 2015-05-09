# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bank_scrap/version'

Gem::Specification.new do |spec|
  spec.name          = 'bank_scrap-cli'
  spec.version       = BankScrap::VERSION
  spec.authors       = [
    'Ismael Sánchez',
    'Javier Cuevas',
    'Fernando Blat',
    'Raúl Marcos'
  ]
  spec.email         = ["root@ismagnu.com"]
  spec.summary       = %q{Get your bank account details.}
  spec.description   = %q{Command line tools to get bank account details from some banks.}
  spec.homepage      = "https://github.com/bank-scrap/bank_scrap"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.required_ruby_version = '~> 2.1'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'byebug', '~> 3.5', '>= 3.5.1'
  spec.add_development_dependency 'fake_bsmobil', '~> 0.1.1'
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'webmock', '~> 1.20'
  spec.add_development_dependency 'yard'

  spec.add_dependency 'bank_scrap-core', '~> 0.1'
  spec.add_dependency 'thor',          '~> 0.19'
  spec.add_dependency 'activesupport', '~> 4.1'
  spec.add_dependency 'money',         '~> 6.5.0'
end
