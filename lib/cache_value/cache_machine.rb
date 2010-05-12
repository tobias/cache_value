require 'active_support/core_ext/array'
require 'active_support/core_ext/class'
require 'active_support/inflector'
require 'active_support/cache'
require 'cache_value/util'
require 'benchmark'

module CacheValue
  class CacheMachine
    include Util

    class << self

      def cache_store=(*store_option)
        @cache_store = store_option ? ActiveSupport::Cache.lookup_store(*store_option) : nil
      end

      def cache_store
        @cache_store ||= ActiveSupport::Cache.lookup_store(:mem_cache_store)
      end

      def lookup(object, method, options, arguments = nil)
        new(object, method, options, arguments).lookup
      end
    end

    attr_accessor :object, :cached_method, :options, :arguments
    
    def initialize(object, method, options, arguments)
      self.object = object
      self.cached_method = method
      self.options = options
      self.arguments = arguments
    end

    def lookup
      value = fetch_and_parse
      value = call_and_store_value unless @fetched
      value
    end
    
    def cache_key
      options = process_options
      if !options[:cache_key] and !object.respond_to?(:cache_key)
        raise ConfigurationException.new("object of class #{object.class.name} does not respond to :cache_key")
      end
      
      cache_key = options[:cache_key] || object.cache_key
      key = cache_key.gsub('/', '_') + "_#{cached_method}"
      key << '_' + hex_digest(arguments) if arguments
      key
    end

    def fetch_and_parse
      data = self.class.cache_store.fetch(cache_key)
      if data
        @fetched = true
        YAML::load(data)
      else
        @fetched = false
        nil
      end
    end

    def call_and_store_value
      without_method = caching_method_names(cached_method).first
      value = nil
      time = Benchmark.realtime do 
        value = arguments ? object.send(without_method, *arguments) : object.send(without_method)
      end
      logger.info "cache_value: cached #{object.class.name}##{cached_method} (will save #{(time*1000).round(1)}ms)"
      
      self.class.cache_store.write(cache_key, value.to_yaml)

      value
    end

    def process_options
      opts = options
      opts = object.send(:method, opts) if opts.is_a?(Symbol)
      opts = opts.call(*([object, cached_method][0,opts.arity])) if opts.respond_to?(:arity)
      
      if opts.respond_to?(:to_hash)
        opts = opts.to_hash 
      else
        opts = { :ttl => opts, :cache_key => nil }
      end
      
      raise ConfigurationException.new('Options must resolve to a hash with a :ttl') unless opts[:ttl]
      
      opts
    end

  end

  class ConfigurationException < StandardError;  end
end
