require 'cache_value/cache_value'

module CacheValue
  ActiveRecord::Base.send(:extend, CacheValue::ClassMethods) if defined?(ActiveRecord::Base)
end
