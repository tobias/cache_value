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
    
    def cache_value(method, *options)
      cached_values[method] = options
    end
    

    def cached_values
      @@cached_values ||= { }
    end

    def build_caching_methods
      cached_values.each do |method, options|
        without_method, with_method = caching_method_names(method)
        class_eval do
          define_method with_method do
            cache_and_return_value(method, options)
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
    def cache_and_return_value(method, options)
      send(self.class.caching_method_names(method).first)
    end
  end


end
