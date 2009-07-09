require 'test_helper'

require 'cache_value/cache_value'

class Cacher 
  extend CacheValue::ClassMethods
  include CacheValue::InstanceMethods
  
  cache_value :do_something, nil
  
  def do_something
    'blech'
  end
end

class CacheValueTest < Test::Unit::TestCase
  
  def setup
    @cacher = Cacher.new
  end

  should 'call the caching method' do
    @cacher.do_something
  end
end
