require 'cache_value/cache_value'

ActiveRecord::Base.send(:extend, CacheValue::ClassMethods) if defined?(ActiveRecord::Base)

