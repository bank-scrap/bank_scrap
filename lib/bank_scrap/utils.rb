module BankScrap
  module Utils
    module_function

    def extract_hash(hash, keys)
      keys.zip(hash.values_at(*keys)).to_h
    end

    def map_hash(hash, mapping)
      mapped = {}

      mapping.each do |key, value|
        case value
          when Hash then mapped.merge! map_hash(hash[key], value)
          else mapped[value] = hash[key]
        end
      end

      mapped
    end

    def transform_hash(hash, transforms)
      transformed = hash.dup

      transforms.each do |key, transform|
        transformed[key] = transform.call hash.fetch(key)
      end

      transformed
    end
  end
end
