require 'cache_value/util'
require 'cache_value/cache_machine'

module CacheValue
  module ClassMethods
    include Util
    
    def cache_value(method, option)
      without_method, with_method = caching_method_names(method)
      class_eval do
        define_method with_method do
          CacheValue::CacheMachine.lookup(self, method, option)
        end
        
        alias_method without_method, method
        alias_method method, with_method
      end
    end
  end

end
