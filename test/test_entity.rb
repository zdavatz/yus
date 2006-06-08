#!/usr/bin/env ruby
# TestEntity -- yus -- 29.05.2006 -- hwyss@ywesee.com


$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'yus/entity'

module Yus
  class TestEntity < Test::Unit::TestCase
    def setup
      @user = Entity.new('user')
    end
    def test_join
      group1 = Entity.new('A Group')
      group2 = Entity.new('Another Group')
      assert_equal([], @user.affiliations)
      @user.join(group1)
      assert_equal([group1], @user.affiliations)
      @user.join(group1)
      assert_equal([group1], @user.affiliations)
      @user.join(group2)
      assert_equal([group1, group2], @user.affiliations)
      @user.join(group1)
      assert_equal([group1, group2], @user.affiliations)
      @user.join(group2)
      assert_equal([group1, group2], @user.affiliations)
    end
    def test_join__circular
      group1 = Entity.new('A Group')
      group2 = Entity.new('Another Group')
      assert_equal([], @user.affiliations)
      assert_nothing_raised {
        @user.join(group1)
      }
      assert_raises(CircularAffiliationError) {
        group1.join(@user) 
      }
      assert_nothing_raised {
        group1.join(group2)
      }
      assert_raises(CircularAffiliationError) {
        group2.join(@user) 
      }
    end
    def test_leave
      group1 = Entity.new('A Group')
      group2 = Entity.new('Another Group')
      group3 = Entity.new('A third Group')
      @user.affiliations.push(group1, group2, group3)
      assert_equal([group1, group2, group3], @user.affiliations)
      @user.leave(group2)
      assert_equal([group1, group3], @user.affiliations)
      @user.leave(group2)
      assert_equal([group1, group3], @user.affiliations)
    end
    def test_grant__action
      assert_equal(false, @user.allowed?('write'))
      @user.grant('write')
      assert_equal(true, @user.allowed?('write'))
      assert_equal(true, @user.allowed?('write', 'Article'))
    end
    def test_grant__action_class
      assert_equal(false, @user.allowed?('write'))
      @user.grant('write', 'Article')
      assert_equal(false, @user.allowed?('write'))
      assert_equal(true, @user.allowed?('write', 'Article'))
    end
    def test_allowed
      assert_equal(false, @user.allowed?('write', 'Article'))
      @user.grant('read', 'Article')
      assert_equal(false, @user.allowed?('write', 'Article'))
      assert_equal(true, @user.allowed?('read', 'Article'))
      assert_equal(false, @user.allowed?('write'))
      assert_equal(false, @user.allowed?('read'))
    end
    def test_allowed__delegated
      group1 = Entity.new('group1')
      assert_equal(false, @user.allowed?('write', 'Article'))
      group1.grant('read', 'Article')
      @user.join(group1)
      assert_equal(false, @user.allowed?('write', 'Article'))
      assert_equal(true, @user.allowed?('read', 'Article'))
      assert_equal(false, @user.allowed?('write'))
      assert_equal(false, @user.allowed?('read'))
    end
    def test_allowed__delegated__once_removed
      group1 = Entity.new('group1')
      group2 = Entity.new('group1')
      assert_equal(false, @user.allowed?('write', 'Article'))
      group1.grant('read', 'Article')
      group2.join(group1)
      @user.join(group2)
      assert_equal(false, @user.allowed?('write', 'Article'))
      assert_equal(true, @user.allowed?('read', 'Article'))
      assert_equal(false, @user.allowed?('write'))
      assert_equal(false, @user.allowed?('read'))
    end
    def test_valid
      assert_equal(true, @user.valid?)
      @user.valid_from = Time.now + 100
      assert_equal(false, @user.valid?)
      @user.valid_until = Time.now - 100
      assert_equal(false, @user.valid?)
      @user.valid_from = Time.now - 200
      assert_equal(false, @user.valid?)
      @user.valid_until = Time.now + 100
      assert_equal(true, @user.valid?)
      @user.valid_until = nil
      assert_equal(true, @user.valid?)
    end
    def test_domain_based_preference
      assert_nil(@user.preference('other'))
      assert_nil(@user.preference('pref'))
      assert_nil(@user.preference('pref', 'domain'))
      assert_nil(@user.preference('pref', 'other'))
      @user.set_preference('pref', 'value', 'domain')
      assert_nil(@user.preference('other'))
      assert_nil(@user.preference('pref'))
      assert_equal('value', @user.preference('pref', 'domain'))
      assert_nil(@user.preference('pref', 'other'))
      @user.set_preference('pref', 'global')
      assert_nil(@user.preference('other'))
      assert_equal('global', @user.preference('pref'))
      assert_equal('value', @user.preference('pref', 'domain'))
      assert_equal('global', @user.preference('pref', 'other'))
    end
  end
end
