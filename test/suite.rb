#!/usr/bin/env ruby
# TestSuite -- yus -- 02.06.2006 -- rwaltert@ywesee.com

$: << File.dirname(File.expand_path(__FILE__))

require 'minitest/autorun'

Dir.foreach(File.dirname(__FILE__)) { |file|
	require file if /^test_.*\.rb$/o.match(file)
}
