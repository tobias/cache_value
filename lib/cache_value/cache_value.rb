module CacheValue
  module Util
    def caching_method_names(method)
      washed_method = method.to_s.sub(/([?!=])$/, '')
      punctuation = $1
      ["#{washed_method}_without_value_caching#{punctuation}",
       "#{washed_method}_with_value_caching#{punctuation}"]
    end
  end
  
  module ClassMethods
    include Util
    
    def cache_value(method, option)
      cached_values[method] = option
    end
    

    def cached_values
      @@cached_values ||= { }
    end

    def build_caching_methods
      cached_values.each do |method, option|
        without_method, with_method = caching_method_names(method)
        class_eval do
          define_method with_method do
            cache_and_return_value(method, option)
          end
          
          alias_method without_method, method
          alias_method method, with_method
        end
      end
    end

   
  end

  module InstanceMethods
    def initialize(*args)
      super
      self.class.build_caching_methods
    end
    
    private
    def cache_and_return_value(method, option)
      CacheValue::CacheMachine.lookup(self, method, option)
    end
  end


end
