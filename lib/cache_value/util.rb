module CacheValue
  module Util
    def caching_method_names(method)
      washed_method = method.to_s.sub(/([?!=])$/, '')
      punctuation = $1
      ["#{washed_method}_without_value_caching#{punctuation}",
       "#{washed_method}_with_value_caching#{punctuation}"]
    end
  end
end
