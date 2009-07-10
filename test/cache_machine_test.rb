require 'test_helper'

require 'cache_value/cache_machine'


class CacheMachineTest < Test::Unit::TestCase
  
  def setup
    @cm = CacheValue::CacheMachine
    @obj = mock
    @method = :some_method
    @value = 2
  end

  context 'cache store' do
    should 'provide a cache store' do
      ::RAILS_ROOT = '/tmp'
      @cm.cache_store.should_not == nil
    end

    context 'default storage dir' do
      should 'raise exception if RAILS_ENV is not set' do
        assert_raise CacheValue::ConfigurationException do
          @cm.default_storage_dir
        end
      end

      should 'point to the tmp in RAILS_ROOT if available' do
        ::RAILS_ROOT = '/tmp'
        @cm.default_storage_dir.should == '/tmp/tmp/cache_value_caches'
      end

      
    end

    teardown do
      Object.send(:remove_const, :RAILS_ROOT) if defined?(RAILS_ROOT)
    end
    
  end
  

  context 'cache key' do
    should 'raise exception if object does not respond_to cache_key' do
      assert_raise CacheValue::ConfigurationException do
        @cm.cache_key(@obj, @method)
      end
    end
    
    context 'with an object that responds to cache_key' do
      setup do
        @obj.expects(:cache_key).returns('a/cache/key')
      end
      
      should 'include the method name at the end' do
        assert_match /_method$/, @cm.cache_key(@obj, :method)
      end

      should 'not have any slashes' do
        assert_no_match %r{/}, @cm.cache_key(@obj, :method)
      end
    end
  end
  
  context 'fetch_and_parse' do
    setup do
      @cache_data = ['data', Time.now]
      @cm.expects(:cache_key).returns('')
    end

    should 'return the data and timestamp when found' do
      @cm.cache_store.expects(:fetch).returns(@cache_data.to_yaml)
      @cm.fetch_and_parse(@obj, @method).should == @cache_data
    end

    should 'return nils when data not found' do
      @cm.cache_store.expects(:fetch).returns(nil)
      @cm.fetch_and_parse(@obj, @method).should == [nil, nil]
    end
  end

  context 'call_and_store_value' do
    setup do
      @obj.expects(:some_method_without_value_caching).returns(2)
      key = 'key'
      @cm.expects(:cache_key).with(@obj, :some_method).returns(key)
      now = Time.now
      Time.stubs(:now).returns(now)
      @cm.cache_store.expects(:write).with(key, [2, Time.now].to_yaml)
    end
    
    should 'return the data' do
      @cm.call_and_store_value(@obj, :some_method).should == 2
    end

  end

  context 'validity of stored value' do
    
    context 'checking by age in seconds' do
      should 'be valid if the value is younger than the age limit' do
        @cm.cached_value_is_still_valid?(@value, Time.now - 30, @obj, @method, 5).should == true
      end

      should 'not be valid if the value is older than the age limit' do
        @cm.cached_value_is_still_valid?(@value, Time.now - 30, @obj, @method, 35).should == false
      end
    end
    
    context 'checking with block' do
      should 'pass the proper fields to the proc' do
        now = Time.now
        proc = lambda { }
        proc.expects(:call).with(@value, now, @obj, @method)

        @cm.cached_value_is_still_valid?(@value, now, @obj, @method, proc)
      end
    end
    should 'raise exceptions if options is incorrect'
  end

  context 'cache lookup' do
    should 'call for the value (and return it) if nothing was cached' do 
      @cm.expects(:fetch_and_parse).with(@obj, @method).returns(nil, nil)
      @cm.expects(:call_and_store_value).with(@obj, @method).returns(@value)
      @cm.lookup(@obj, @method, nil).should == @value
    end

    should 'call for the value (and return it) if the value is no longer valid' do
      now = Time.now
      @cm.expects(:fetch_and_parse).with(@obj, @method).returns([2, now])
      @cm.expects(:cached_value_is_still_valid?).with(@value, now, @obj, @method, 2).returns(false)
      @cm.expects(:call_and_store_value).with(@obj, @method).returns(@value)
      @cm.lookup(@obj, @method, 2).should == @value
    end
    
    should 'not call and store if the cached value is valid' do
      @cm.expects(:fetch_and_parse).with(@obj, @method).returns([2, Time.now])
      @cm.expects(:cached_value_is_still_valid?).returns(true)
      @cm.expects(:call_and_store_value).never
      @cm.lookup(@obj, @method, 2).should == @value
    end
    
    should 'be able to cache a nil value' do
            @cm.expects(:fetch_and_parse).with(@obj, @method).returns([nil, Time.now])
      @cm.expects(:cached_value_is_still_valid?).returns(true)
      @cm.expects(:call_and_store_value).never
      @cm.lookup(@obj, @method, 2).should == nil
    end
      
  end
end
