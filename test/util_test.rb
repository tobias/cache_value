require 'test_helper'

require 'cache_value/util'


class UtilTest < Test::Unit::TestCase
  include CacheValue::Util
  
  context 'hex_digest' do
    should 'return the same digest for identical hashes' do 
      hex_digest({ :ha => 'ha'}).should == hex_digest({ :ha => 'ha'})
    end
  end
  
end
