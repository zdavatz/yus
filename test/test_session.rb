#!/usr/bin/env ruby
# TestSession -- yus -- 02.06.2006 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'flexmock'
require 'yus/session'

module Yus
  class Session
    public :touch!
  end
  class TestEntitySession < Test::Unit::TestCase
    def setup
      @user = FlexMock.new
      @persistence = FlexMock.new
      @session = EntitySession.new(@persistence, @user, 'domain', 0.5)
    end
    def test_expired
      assert_equal(false, @session.expired?)
      sleep(1)
      assert_equal(true, @session.expired?)
    end
    def test_touch
      sleep(1)
      assert_equal(true, @session.expired?)
      @session.touch!
      assert_equal(false, @session.expired?)
    end
    def test_create_entity__not_allowed
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        false
      }
      assert_raises(NotPrivilegedError) { 
        @session.create_entity('name')
      }
    end
    def test_create_entity__success
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      @persistence.mock_handle(:find_entity, 1) {}
      @persistence.mock_handle(:add_entity, 1) { |entity|
        assert_instance_of(Entity, entity)
        assert_equal('name', entity.name)
      }
      @session.create_entity('name')
    end
    def test_create_entity__duplicate
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      @persistence.mock_handle(:find_entity, 1) { 'something' }
      assert_raises(DuplicateNameError) {
        @session.create_entity('name')
      }
    end
    def test_destroy
      assert_equal(false, @session.expired?)
      @session.destroy!
      assert_equal(true, @session.expired?)
      assert_nil(@session.instance_variable_get('@persistence'))
      assert_nil(@session.instance_variable_get('@user'))
    end
    def test_entities__not_allowed
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        false
      }
      assert_raises(NotPrivilegedError) { 
        @session.entities
      }
    end
    def test_entities__allowed
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      @persistence.mock_handle(:entities) { [] }
      assert_nothing_raised { 
        assert_equal([], @session.entities)
      }
    end
  end
end
