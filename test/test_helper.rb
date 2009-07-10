require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'matchy'
require 'mocha'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'cache_value'

class Test::Unit::TestCase
end
