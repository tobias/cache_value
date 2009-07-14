require 'active_support/core_ext/array'
require 'active_support/core_ext/class'
require 'active_support/inflector'
require 'active_support/cache'
require 'cache_value/util'

module CacheValue
  class CacheMachine
    extend Util
    
    class << self

      def cache_store=(*store_option)
        @cache_store = store_option ? ActiveSupport::Cache.lookup_store(store_option) : nil
      end
      
      def cache_store
        @cache_store ||= ActiveSupport::Cache.lookup_store(:file_store, default_storage_dir)
      end

      def default_storage_dir
        raise ConfigurationException.new('Not running under rails. Set the cache_store type and location manually using CacheValue::CacheMachine.store_option=') unless defined?(RAILS_ROOT)
        File.join(RAILS_ROOT, 'tmp', 'cache_value_caches')
      end

      def lookup(object, method, options, arguments = nil)
        value, last_cached = fetch_and_parse(object, method, arguments)
        if !last_cached or !cached_value_is_still_valid?(value, last_cached, object, method, options)
          value = call_and_store_value(object, method, arguments)
        end
        
        value
      end
      
      def cache_key(object, method, arguments = nil)
        raise ConfigurationException.new("object of class #{object.class.name} does not respond to :cache_key") unless object.respond_to?(:cache_key)
        key = object.cache_key.gsub('/', '_') + "_#{method}"
        key << '_' + hex_digest(arguments) if arguments
        key
      end

      def fetch_and_parse(object, method, arguments = nil)
        data = cache_store.fetch(cache_key(object, method, arguments))
        if data
          YAML::load(data)
        else
          [nil, nil]
        end
      end

      def call_and_store_value(object, method, arguments = nil)
        without_method = caching_method_names(method).first
        value = arguments ? object.send(without_method, *arguments) : object.send(without_method)
        cache_store.write(cache_key(object, method, arguments), [value, Time.now].to_yaml)
        
        value
      end

      def cached_value_is_still_valid?(value, cached_age, object, method, options)
        options = object.send(:method, options) if options.is_a?(Symbol)
        if options.respond_to?(:arity)          
          options.call(*([cached_age, object, method][0,options.arity]))
        else
          cached_age > Time.now - options
        end
      end

    end
  end

  class ConfigurationException < StandardError
  end
end
