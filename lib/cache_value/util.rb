require 'sha1'

module CacheValue
  module Util
    def caching_method_names(method)
      washed_method = method.to_s.sub(/([?!=])$/, '')
      punctuation = $1
      ["#{washed_method}_without_value_caching#{punctuation}",
       "#{washed_method}_with_value_caching#{punctuation}"]
    end

    def hex_digest(values)
      Digest::SHA1.hexdigest(stringify_value(values))
    end
    
    protected
    def stringify_value(value)
      if value.respond_to?(:to_str)
        value.to_str
      elsif value.respond_to?(:cache_key)
        value.cache_key.to_s
      elsif value.respond_to?(:collect)
        value.collect { |x| stringify_value(x) }.join
      else
        value.to_s
      end
    end
    
  end
end
