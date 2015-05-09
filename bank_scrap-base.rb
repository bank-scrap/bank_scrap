
module BankScrap
  class Specification < ::Gem::Specification
    def initialize(*args)
      super(*args)

      self.version       = BankScrap::VERSION
      self.homepage      = 'https://github.com/bank-scrap/bank_scrap'
      self.license       = 'MIT'

      self.require_paths = ['lib']

      self.required_ruby_version = '~> 2.0'

      self.add_development_dependency 'rspec', '~> 3.2'

      yield self if block_given?
    end
  end
end
