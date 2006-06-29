#!/usr/bin/env ruby
# TestSession -- yus -- 02.06.2006 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'flexmock'
require 'yus/session'
require 'digest/sha2'

module Yus
  class Session
    public :touch!
  end
  class TestAutoSession < Test::Unit::TestCase
    def setup
      @config = FlexMock.new
      @config.mock_handle(:session_timeout) { 0.5 }
      @persistence = FlexMock.new
      @logger = FlexMock.new
      @logger.mock_handle(:info) {}
      @logger.mock_handle(:debug) {}
      @needle = FlexMock.new
      @needle.mock_handle(:persistence) { @persistence }
      @needle.mock_handle(:config) { @config }
      @needle.mock_handle(:logger) { @logger }
      @session = AutoSession.new(@needle, 'domain')
    end
    def test_get_entity_preference__no_user
      @persistence.mock_handle(:find_entity, 1) {}
      assert_raises(UnknownEntityError) {
        @session.get_entity_preference('name', 'preference_key', 'domain')
      }
      @persistence.mock_verify
    end
    def test_get_entity_preference__no_preference
      user = FlexMock.new
      user.mock_handle(:get_preference) { |key, domain|
        assert_equal('preference_key', key)
        assert_equal('domain', domain)
        nil
      }
      @persistence.mock_handle(:find_entity, 1) { user }
      res = nil
      assert_nothing_raised {
        res = @session.get_entity_preference('name', 'preference_key', 'domain')
      }
      assert_nil(res)
      @persistence.mock_verify
    end
    def test_get_entity_preference__success
      user = FlexMock.new
      user.mock_handle(:get_preference) { |key, domain|
        assert_equal('preference_key', key)
        assert_equal('domain', domain)
        'value'
      }
      @persistence.mock_handle(:find_entity, 1) { user }
      res = nil
      assert_nothing_raised {
        res = @session.get_entity_preference('name', 'preference_key', 'domain')
      }
      assert_equal('value', res)
      @persistence.mock_verify
    end
    def test_get_entity_preferences__no_user
      @persistence.mock_handle(:find_entity, 1) {}
      assert_raises(UnknownEntityError) {
        @session.get_entity_preferences('name', ['preference_key'], 'domain')
      }
      @persistence.mock_verify
    end
    def test_get_entity_preferences__no_preference
      user = FlexMock.new
      user.mock_handle(:get_preference) { |key, domain|
        assert_equal('preference_key', key)
        assert_equal('domain', domain)
        nil
      }
      @persistence.mock_handle(:find_entity, 1) { user }
      res = nil
      assert_nothing_raised {
        res = @session.get_entity_preferences('name', ['preference_key'], 'domain')
      }
      assert_equal({'preference_key' => nil}, res)
      @persistence.mock_verify
    end
    def test_get_entity_preferences__success
      user = FlexMock.new
      user.mock_handle(:get_preference) { |key, domain|
        assert_equal('preference_key', key)
        assert_equal('domain', domain)
        'value'
      }
      @persistence.mock_handle(:find_entity, 1) { user }
      res = nil
      assert_nothing_raised {
        res = @session.get_entity_preferences('name', ['preference_key'], 'domain')
      }
      assert_equal({'preference_key' => 'value'}, res)
      @persistence.mock_verify
    end
    def test_set_entity_preference__no_user
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal('name', name)
        nil
      }
      assert_raises(UnknownEntityError) {
        @session.set_entity_preference('name', 'key', 'value')
      }
    end
    def test_set_entity_preference__success
      entity = FlexMock.new
      value = nil
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal('name', name)
        entity
      }
      entity.mock_handle(:get_preference) { |key, domain|
        assert_equal('key', key)
        value
      }
      entity.mock_handle(:set_preference, 1) { |key, val, domain|
        assert_equal('key', key)
        assert_equal('value', val)
        value = val
      }
      @persistence.mock_handle(:save_entity, 1) { |user| 
        assert_equal(entity, user) 
      }
      @session.set_entity_preference('name', 'key', 'value')
      @session.set_entity_preference('name', 'key', 'other')
      @persistence.mock_verify
      entity.mock_verify
    end
    def test_create_entity__success
      @config.mock_handle(:digest) { Digest::SHA256 }
      @persistence.mock_handle(:find_entity, 1) {}
      @persistence.mock_handle(:add_entity, 1) { |entity|
        assert_instance_of(Entity, entity)
        assert_equal('name', entity.name)
      }
      @session.create_entity('name', 'pass')
    end
    def test_create_entity__duplicate
      @persistence.mock_handle(:find_entity, 1) { 'something' }
      assert_raises(DuplicateNameError) {
        @session.create_entity('name')
      }
    end
    def test_allowed
      assert_equal(false, @session.allowed?('anything at all'))
    end
    def test_entity_allowed__no_user
      @persistence.mock_handle(:find_entity, 1) {}
      assert_raises(UnknownEntityError) {
        @session.entity_allowed?('name', 'action', 'key')
      }
      @persistence.mock_verify
    end
    def test_entity_allowed
      user = FlexMock.new
      expecteds = [['action1', nil], ['action2', 'key']]
      user.mock_handle(:allowed?) { |action, key|
        eact, ekey = expecteds.shift
        assert_equal(eact, action)
        assert_equal(ekey, key)
        action == 'action2'
      }
      @persistence.mock_handle(:find_entity, 2) { user }
      assert_equal(false, @session.entity_allowed?('name', 'action1'))
      assert_equal(true, @session.entity_allowed?('name', 'action2', 'key'))
      @persistence.mock_verify
    end
    def test_reset_entity_password__no_user
      @persistence.mock_handle(:find_entity, 1) {}
      assert_raises(UnknownEntityError) {
        @session.reset_entity_password('name', 'token', 'password')
      }
      @persistence.mock_verify
    end
    def test_reset_entity_password__no_token
      user = FlexMock.new
      user.mock_handle(:allowed?) { |action, token|
        assert_equal('reset_password', action)
        assert_equal('token', token)
        false
      }
      @persistence.mock_handle(:find_entity, 1) { user }
      res = nil
      assert_raises(NotPrivilegedError) {
        @session.reset_entity_password('name', 'token', 'password')
      }
      @persistence.mock_verify
    end
    def test_reset_entity_password__success
      user = FlexMock.new
      user.mock_handle(:allowed?) { |action, token|
        assert_equal('reset_password', action)
        assert_equal('token', token)
        true
      }
      user.mock_handle(:passhash=, 1) { |hash|
        assert_equal(Digest::SHA256.hexdigest('password'), hash)
      }
      user.mock_handle(:revoke) { |action, token|
        assert_equal('reset_password', action)
        assert_equal('token', token)
      }
      @config.mock_handle(:digest) { Digest::SHA256 }
      @persistence.mock_handle(:find_entity, 1) { user }
      @persistence.mock_handle(:save_entity, 1) { |entity|
        assert_equal(user, entity)
      }
      assert_nothing_raised {
        @session.reset_entity_password('name', 'token', 'password')
      }
      user.mock_verify
      @persistence.mock_verify
    end
    def test_grant__no_user
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal('username', name)
        nil
      }
      assert_raises(UnknownEntityError) {
        @session.grant('username', 'action')
      }
    end
    def test_grant__success_key
      entity = FlexMock.new
      entity.mock_handle(:grant) { |action, key|
        assert_equal('action', action)
        assert_equal('key', key)
      }
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal('username', name)
        entity
      }
      @persistence.mock_handle(:save_entity, 1) { |user| 
        assert_equal(entity, user) 
      }
      @session.grant('username', 'action', 'key')
      @persistence.mock_verify
    end
  end
  class TestEntitySession < Test::Unit::TestCase
    def setup
      @config = FlexMock.new
      @config.mock_handle(:session_timeout) { 0.5 }
      @user = FlexMock.new
      @persistence = FlexMock.new
      @logger = FlexMock.new
      @logger.mock_handle(:info) {}
      @logger.mock_handle(:debug) {}
      @needle = FlexMock.new
      @needle.mock_handle(:persistence) { @persistence }
      @needle.mock_handle(:config) { @config }
      @needle.mock_handle(:logger) { @logger }
      @session = EntitySession.new(@needle, @user, 'domain')
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
    def test_name
      @user.mock_handle(:name) { 'name' }
      assert_equal('name', @session.name)
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
    def test_find_entity__not_allowed
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        false
      }
      assert_raises(NotPrivilegedError) {
        @session.find_entity('username')
      }
    end
    def test_find_entity__success
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal('username', name)
        'found'
      }
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      assert_equal('found', @session.find_entity('username'))
    end
    def test_grant__not_allowed
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('grant', action)
        assert_equal('action', key)
        false
      }
      assert_raises(NotPrivilegedError) {
        @session.grant('username', 'action')
      }
    end
    def test_grant__no_user
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal('username', name)
        nil
      }
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('grant', action)
        assert_equal('action', key)
        true
      }
      assert_raises(UnknownEntityError) {
        @session.grant('username', 'action')
      }
    end
    def test_grant__success_everything
      entity = FlexMock.new
      entity.mock_handle(:grant) { |action, key|
        assert_equal('action', action)
        assert_equal(:everything, key)
      }
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal('username', name)
        entity
      }
      @persistence.mock_handle(:save_entity, 1) { |user| 
        assert_equal(entity, user) 
      }
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('grant', action)
        assert_equal('action', key)
        true
      }
      @session.grant('username', 'action')
      @persistence.mock_verify
    end
    def test_grant__success_key
      entity = FlexMock.new
      entity.mock_handle(:grant) { |action, key|
        assert_equal('action', action)
        assert_equal('key', key)
      }
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal('username', name)
        entity
      }
      @persistence.mock_handle(:save_entity, 1) { |user| 
        assert_equal(entity, user) 
      }
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('grant', action)
        assert_equal('action', key)
        true
      }
      @session.grant('username', 'action', 'key')
      @persistence.mock_verify
    end
    def test_valid__success
      @user.mock_handle(:valid?) { true }
      assert_equal(true, @session.valid?)
    end
    def test_valid__failure
      @user.mock_handle(:valid?) { false }
      assert_equal(false, @session.valid?)
    end
    def test_set_password__not_allowed
      @user.mock_handle(:allowed?) { |action, name|
        assert_equal('set_password', action)
        assert_equal('name', name)
        false
      }
      assert_raises(NotPrivilegedError) {
        @session.set_password('name', 'cleartext') 
      }
    end
    def test_set_password__no_user
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal('username', name)
        nil
      }
      @user.mock_handle(:allowed?) { |action, name|
        assert_equal('set_password', action)
        assert_equal('username', name)
        true
      }
      assert_raises(UnknownEntityError) {
        @session.set_password('username', 'cleartext') 
      }
    end
    def test_set_password__success
      entity = FlexMock.new
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal('username', name)
        entity
      }
      @persistence.mock_handle(:save_entity, 1) { |user| 
        assert_equal(entity, user) 
      }
      @user.mock_handle(:allowed?) { |action, name|
        assert_equal('set_password', action)
        assert_equal('username', name)
        true
      }
      @config.mock_handle(:digest) { Digest::SHA256 }
      entity.mock_handle(:passhash=) { |hash|
        assert_equal(Digest::SHA256.hexdigest('cleartext'), hash)
      }
      @session.set_password('username', 'cleartext') 
      @persistence.mock_verify
    end
    def test_rename__not_allowed
      @user.mock_handle(:allowed?) { |action, name|
        assert_equal('edit', action)
        assert_equal('yus.entities', name)
        false
      }
      assert_raises(NotPrivilegedError) {
        @session.rename('oldname', 'newname') 
      }
    end
    def test_rename__no_user
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal('oldname', name)
        nil
      }
      @user.mock_handle(:allowed?) { |action, name|
        assert_equal('edit', action)
        assert_equal('yus.entities', name)
        true
      }
      assert_raises(UnknownEntityError) {
        @session.rename('oldname', 'newname') 
      }
    end
    def test_rename__duplicate_name
      entity1 = FlexMock.new
      entity2 = FlexMock.new
      entities = {
        'oldname' => entity1,
        'newname' => entity2,
      }
      @persistence.mock_handle(:find_entity) { |name|
        entities[name]
      }
      @user.mock_handle(:allowed?) { |action, name|
        assert_equal('edit', action)
        assert_equal('yus.entities', name)
        true
      }
      assert_raises(DuplicateNameError) {
        @session.rename('oldname', 'newname') 
      }
    end
    def test_rename__success
      entity = FlexMock.new
      entity.mock_handle(:revoke, 1) { |action, item|
        assert_equal('set_password', action)
        assert_equal('oldname', item)
      }
      entity.mock_handle(:grant, 1) { |action, item|
        assert_equal('set_password', action)
        assert_equal('newname', item)
      }
      entity.mock_handle(:rename) { |newname|
        assert_equal('newname', newname)
      }
      entities = {
        'oldname' => entity,
        'newname' => nil,
      }
      @persistence.mock_handle(:find_entity) { |name|
        entities[name]
      }
      @persistence.mock_handle(:save_entity, 1) { |user|
        assert_equal(entity, user)
      }
      @user.mock_handle(:allowed?) { |action, name|
        assert_equal('edit', action)
        assert_equal('yus.entities', name)
        true
      }
      @session.rename('oldname', 'newname') 
      @persistence.mock_verify
      entity.mock_verify
    end
    def test_revoke__not_allowed
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('grant', action)
        assert_equal('action', key)
        false
      }
      assert_raises(NotPrivilegedError) {
        @session.revoke('username', 'action')
      }
    end
    def test_revoke__no_user
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal('username', name)
        nil
      }
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('grant', action)
        assert_equal('action', key)
        true
      }
      assert_raises(UnknownEntityError) {
        @session.revoke('username', 'action')
      }
    end
    def test_revoke__success_everything
      entity = FlexMock.new
      entity.mock_handle(:revoke) { |action, key|
        assert_equal('action', action)
        assert_equal(:everything, key)
      }
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal('username', name)
        entity
      }
      @persistence.mock_handle(:save_entity, 1) { |user| 
        assert_equal(entity, user) 
      }
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('grant', action)
        assert_equal('action', key)
        true
      }
      @session.revoke('username', 'action')
      @persistence.mock_verify
    end
    def test_revoke__success_key
      entity = FlexMock.new
      entity.mock_handle(:revoke) { |action, key|
        assert_equal('action', action)
        assert_equal('key', key)
      }
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal('username', name)
        entity
      }
      @persistence.mock_handle(:save_entity, 1) { |user| 
        assert_equal(entity, user) 
      }
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('grant', action)
        assert_equal('action', key)
        true
      }
      @session.revoke('username', 'action', 'key')
      @persistence.mock_verify
    end
    def test_affiliate__not_allowed
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        false
      }
      assert_raises(NotPrivilegedError) { 
        @session.affiliate('name', 'group')
      }
    end
    def test_affiliate__no_user
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal('name', name)
        nil
      }
      assert_raises(UnknownEntityError) {
        @session.affiliate('name', 'group')
      }
    end
    def test_affiliate__no_group
      user = FlexMock.new
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      names = ['name', 'group']
      entities = [user, nil]
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal(names.shift, name)
        entities.shift
      }
      assert_raises(UnknownEntityError) {
        @session.affiliate('name', 'group')
      }
    end
    def test_affiliate__success
      @persistence.mock_handle(:save_entity) {}
      user = FlexMock.new
      group = FlexMock.new
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      names = ['name', 'group']
      entities = [user, group]
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal(names.shift, name)
        entities.shift
      }
      user.mock_handle(:join, 1) { |arg|
        assert_equal(group, arg)
      }
      @session.affiliate('name', 'group')
      user.mock_verify
    end
    def test_disaffiliate__not_allowed
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        false
      }
      assert_raises(NotPrivilegedError) { 
        @session.disaffiliate('name', 'group')
      }
    end
    def test_disaffiliate__no_user
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal('name', name)
        nil
      }
      assert_raises(UnknownEntityError) {
        @session.disaffiliate('name', 'group')
      }
    end
    def test_disaffiliate__no_group
      user = FlexMock.new
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      names = ['name', 'group']
      entities = [user, nil]
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal(names.shift, name)
        entities.shift
      }
      assert_raises(UnknownEntityError) {
        @session.disaffiliate('name', 'group')
      }
    end
    def test_disaffiliate__success
      @persistence.mock_handle(:save_entity) {}
      user = FlexMock.new
      group = FlexMock.new
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      names = ['name', 'group']
      entities = [user, group]
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal(names.shift, name)
        entities.shift
      }
      user.mock_handle(:leave, 1) { |arg|
        assert_equal(group, arg)
      }
      @session.disaffiliate('name', 'group')
      user.mock_verify
    end
    def test_set_entity_preference__not_allowed
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        false
      }
      assert_raises(NotPrivilegedError) { 
        @session.set_entity_preference('name', 'key', 'value')
      }
    end
    def test_set_entity_preference__no_user
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal('name', name)
        nil
      }
      assert_raises(UnknownEntityError) {
        @session.set_entity_preference('name', 'key', 'value')
      }
    end
    def test_set_entity_preference__success
      entity = FlexMock.new
      @user.mock_handle(:allowed?) { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      @persistence.mock_handle(:find_entity) { |name|
        assert_equal('name', name)
        entity
      }
      entity.mock_handle(:set_preference, 1) { |key, val|
        assert_equal('key', key)
        assert_equal('value', val)
      }
      @persistence.mock_handle(:save_entity, 1) { |user| 
        assert_equal(entity, user) 
      }
      @session.set_entity_preference('name', 'key', 'value')
      @persistence.mock_verify
      entity.mock_verify
    end
    def test_set_preference
      @user.mock_handle(:set_preference, 1) { |key, val, domain|
        assert_equal('key', key)
        assert_equal('value', val)
        assert_equal('domain', domain)
      }
      @persistence.mock_handle(:save_entity, 1) { |user| 
        assert_equal(@user, user) 
      }
      @session.set_preference('key', 'value')
      @persistence.mock_verify
      @user.mock_verify
    end
    def test_set_preferences
      @user.mock_handle(:set_preference, 2) { |key, val, domain| }
      @persistence.mock_handle(:save_entity, 1) { |user| 
        assert_equal(@user, user) 
      }
      @session.set_preferences({'key1' => 'value1', 'key2' => 'value2'})
      @persistence.mock_verify
      @user.mock_verify
    end
    def test_get_entity_preference__no_preference
      @user.mock_handle(:get_preference) { |key, domain|
        assert_equal('preference_key', key)
        assert_equal('domain', domain)
        nil
      }
      res = nil
      assert_nothing_raised {
        res = @session.get_preference('preference_key')
      }
      assert_nil(res)
    end
    def test_get_entity_preference__success
      @user.mock_handle(:get_preference) { |key, domain|
        assert_equal('preference_key', key)
        assert_equal('domain', domain)
        'value'
      }
      res = nil
      assert_nothing_raised {
        res = @session.get_preference('preference_key')
      }
      assert_equal('value', res)
      @persistence.mock_verify
    end
    def test_ping
      assert_equal(true, @session.ping)
    end
  end
  class TestRootSession < Test::Unit::TestCase
    def setup
      @config = FlexMock.new
      @config.mock_handle(:session_timeout) { 0.5 }
      @persistence = FlexMock.new
      @logger = FlexMock.new
      @logger.mock_handle(:info) {}
      @logger.mock_handle(:debug) {}
      @needle = FlexMock.new
      @needle.mock_handle(:persistence) { @persistence }
      @needle.mock_handle(:config) { @config }
      @needle.mock_handle(:logger) { @logger }
      @session = RootSession.new(@needle)
    end
    def test_valid
      assert_equal(true, @session.valid?)
    end
    def test_allowed
      assert_equal(true, @session.allowed?('anything'))
    end
    def test_name
      @config.mock_handle(:root_name) { 'root_name' }
      assert_equal('root_name', @session.name)
    end
  end
end
