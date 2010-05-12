require 'test_helper'

require 'cache_value/cache_machine'

require 'logger'

class CacheMachineTest < Test::Unit::TestCase
  ::RAILS_DEFAULT_LOGGER = Logger.new('/dev/null')
  
  def setup
    @obj = mock
    @method = :some_method
    @value = 2
    @cm = CacheValue::CacheMachine.new(@obj, @method, 15, nil)
  end

  context 'at the class level' do
    should 'provide a cache store' do
      CacheValue::CacheMachine.cache_store.should_not == nil
    end
    
    should 'delegate the lookup call to an instance' do
      CacheValue::CacheMachine.expects(:new).with(1,2,3,4).returns(@cm)
      @cm.expects(:lookup)
      CacheValue::CacheMachine.lookup(1,2,3,4)
    end
  end
  

  context 'cache key' do
    should 'raise exception if object does not respond_to cache_key and no cache key provided in the options' do
      assert_raise CacheValue::ConfigurationException do
        @cm.cache_key
      end
    end

    should 'use the cache_key if provided in options' do
      @cm.options = { :cache_key => 'a_key', :ttl => 1 }
      @cm.cache_key.should =~ /a_key/
    end
    
    context 'with an object that responds to cache_key' do
      setup do
        @obj.expects(:cache_key).returns('a/cache/key')
      end
      
      should 'include the method name at the end' do
        assert_match /_some_method$/, @cm.cache_key
      end

      should 'not have any slashes' do
        assert_no_match %r{/}, @cm.cache_key
      end
    end

    context 'with arguments' do
      setup do
        @obj.expects(:cache_key).returns('a/cache/key')
      end

      should 'should include the argument hash in the key' do
        now = Time.now
        args = [1, 2, now]
        @cm.arguments = args
        assert_match /_some_method_#{@cm.send(:hex_digest, args)}$/, @cm.cache_key
      end

    end
  end
  
  context 'fetch_and_parse' do
    setup do
      @cache_data = 'data'
      @cm.expects(:cache_key).returns('')
    end

    should 'return the data when found' do
      @cm.class.cache_store.expects(:fetch).returns(@cache_data.to_yaml)
      @cm.fetch_and_parse.should == @cache_data
    end

    should 'return nil when data not found' do
      @cm.class.cache_store.expects(:fetch).returns(nil)
      @cm.fetch_and_parse.should == nil
    end
  end

  context 'call_and_store_value' do
    setup do
      @obj.expects(:some_method_without_value_caching).returns(2)
      key = 'key'
      @cm.expects(:cache_key).returns(key)
      now = Time.now
      Time.stubs(:now).returns(now)
      @cm.class.cache_store.expects(:write).with(key, 2.to_yaml, { :expires_in => 15 })
    end
    
    should 'return the data' do
      @cm.call_and_store_value.should == 2
    end

  end
  
  context 'processing the options' do

    should 'return a hash if given a hash' do
      @cm.options = { :ttl => 15 }
      @cm.process_options.should == { :ttl => 15 }
    end
    
    context 'checking with block' do
      should 'pass the proper fields to the proc' do
        now = Time.now
        proc = lambda { |a,b|}
        proc.expects(:call).with(@obj, @method).returns(1)
        @cm.options = proc
        
        @cm.process_options
      end

      should 'only pass the object if the proc only takes one arg' do
        now = Time.now
        proc = lambda { |a|}
        proc.expects(:call).with(@obj).returns({ :ttl => 1})
        @cm.options = proc
        
        @cm.process_options
      end
    end

    context 'checking with symbol' do
      setup do
        @object = Object.new
        def @object.the_method(a,b)
          {:ttl => 1}
        end
        
      end

      should 'call the method for the symbol on the object' do
        @cm.options = :the_method
        @cm.object = @object
        @cm.process_options.should == { :ttl => 1 }
      end
     
    end
    
    should 'raise exception if options do not resolve to a hash with :ttl' do
      @cm.options = lambda { { }}
      assert_raise CacheValue::ConfigurationException do
        @cm.process_options
      end
    end
    
  end

  context 'cache lookup' do
    should 'call for the value (and return it) if nothing was cached' do
      @cm.expects(:fetch_and_parse).returns(nil)
      @cm.expects(:call_and_store_value).returns(@value)
      @cm.lookup.should == @value
    end

    should 'be able to cache a nil value' do
      @cm.class.cache_store.expects(:fetch).returns(nil.to_yaml)
      @cm.stubs(:cache_key).returns(nil)
      @cm.expects(:call_and_store_value).never
      @cm.lookup.should == nil
    end
    
    context 'with a cached value' do
      setup do
        @cm.class.cache_store.expects(:fetch).returns(1.to_yaml)
        @cm.stubs(:cache_key).returns('asf')
      end

      should 'not try to cache the value' do
        @cm.expects(:call_and_store_value).never
        @cm.lookup
      end

      should 'actually return the cached value' do
        @cm.lookup.should == 1
      end
    end
  end
end
