require 'test_helper'

require 'cache_value/cache_value'

class CacheTestClass
  extend CacheValue::ClassMethods
  
  def do_something
    'blech'
  end
  
  cache_value :do_something, 'yo'

end

class CacheValueTest < Test::Unit::TestCase
  
  def setup
    @cacher = CacheTestClass.new
  end

  should 'delegate the cache lookup to CacheMachine' do
    CacheValue::CacheMachine.expects(:lookup).with(@cacher, :do_something, 'yo')
    @cacher.do_something
  end
  
  context 'aliased methods' do
    
    context 'generate caching method names' do
      should 'generate vanilla names' do
        @cacher.class.caching_method_names(:vanilla).should == %w{ vanilla_without_value_caching vanilla_with_value_caching }
      end

      should 'generate chocolate! names' do
        @cacher.class.caching_method_names(:chocolate!).should == %w{ chocolate_without_value_caching! chocolate_with_value_caching! }
      end
      
      should 'generate strawberry? names' do
        @cacher.class.caching_method_names(:strawberry?).should == %w{ strawberry_without_value_caching? strawberry_with_value_caching? }
      end
      
    end

    should 'have aliased a with method' do
      @cacher.respond_to?(:do_something_with_value_caching).should == true
    end

    should 'have aliased a without method' do
      @cacher.respond_to?(:do_something_without_value_caching).should == true
    end
  end
end
