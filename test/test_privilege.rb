#!/usr/bin/env ruby
# TestPrivilege -- yus -- 31.05.2006 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

gem 'minitest'
require 'minitest/autorun'
require 'yus/privilege'

module Yus
  class TestPrivilege <Minitest::Test
    def setup
      @privilege = Privilege.new
    end
    def test_grant
      assert_equal(false, @privilege.granted?('Article'))
      @privilege.grant('Article')
      assert_equal(false, @privilege.granted?('Book'))
      assert_equal(true, @privilege.granted?('Article'))
    end
    def test_grant__timed
      assert_equal(false, @privilege.granted?('Article'))
      @privilege.grant('Article', Time.now)
      assert_equal(false, @privilege.granted?('Article'))
      @privilege.grant('Article', Time.now + 0.5)
      assert_equal(true, @privilege.granted?('Article'))
      sleep(1)
      assert_equal(false, @privilege.granted?('Article'))
    end
    def test_grant__everything
      assert_equal(false, @privilege.granted?('Article'))
      @privilege.grant(:everything)
      assert_equal(true, @privilege.granted?('Article'))
    end
    def test_grant__wildcard
      assert_equal(false, @privilege.granted?('org.oddb.company'))
      @privilege.grant('org.oddb.*')
      assert_equal(true, @privilege.granted?('org.oddb.company'))
      assert_equal(false, @privilege.granted?('org.oddb'))
      assert_equal(false, @privilege.granted?('org.foo.company'))
    end
    def test_revoke
      @privilege.grant('Article')
      assert_equal(true, @privilege.granted?('Article'))
      @privilege.revoke('Article')
      assert_equal(false, @privilege.granted?('Article'))
    end
    def test_revoke__timed
      @privilege.grant('Article')
      assert_equal(true, @privilege.granted?('Article'))
      @privilege.revoke('Article', Time.now + 0.5)
      assert_equal(true, @privilege.granted?('Article'))
      sleep(1)
      assert_equal(false, @privilege.granted?('Article'))
    end
  end
end
