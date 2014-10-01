#!/usr/bin/env ruby
# TestSession -- yus -- 02.06.2006 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

gem "minitest"
require "minitest/autorun"
require 'flexmock'
require 'yus/session'
require 'digest/sha2'
require 'fileutils'
require File.expand_path(File.dirname(__FILE__)+'/helpers.rb')

module Yus
  class Session
    public :touch!
  end
  class TestAutoSession < Minitest::Test
    def setup
      @config = FlexMock.new
      @config.should_receive(:session_timeout).and_return { 0.5 }
      @persistence = FlexMock.new
      @logger = FlexMock.new
      @logger.should_receive(:info).and_return {}
      @logger.should_receive(:debug).and_return {}
      @needle = FlexMock.new
      @needle.should_receive(:persistence).and_return { @persistence }
      @needle.should_receive(:config).and_return { @config }
      @needle.should_receive(:logger).and_return { @logger }
      @session = AutoSession.new(@needle, 'domain')
    end
    def test_get_entity_preference__no_user
      @persistence.should_receive(:find_entity, 1).times(1).and_return {}
      assert_raises(UnknownEntityError) {
        @session.get_entity_preference('name', 'preference_key', 'domain')
      }
    end
    def test_get_entity_preference__no_preference
      user = FlexMock.new
      user.should_receive(:get_preference).and_return { |key, domain|
        assert_equal('preference_key', key)
        assert_equal('domain', domain)
        nil
      }
      @persistence.should_receive(:find_entity, 1).times(1).and_return { user }
      res = nil
      res = @session.get_entity_preference('name', 'preference_key', 'domain')
      assert_nil(res)
    end
    def test_get_entity_preference__success
      user = FlexMock.new
      user.should_receive(:get_preference).and_return { |key, domain|
        assert_equal('preference_key', key)
        assert_equal('domain', domain)
        'value'
      }
      @persistence.should_receive(:find_entity, 1).times(1).and_return { user }
      res = nil
      res = @session.get_entity_preference('name', 'preference_key', 'domain')
      assert_equal('value', res)
    end
    def test_get_entity_preferences__no_user
      @persistence.should_receive(:find_entity, 1).times(1).and_return {}
      assert_raises(UnknownEntityError) {
        @session.get_entity_preferences('name', ['preference_key'], 'domain')
      }
    end
    def test_get_entity_preferences__no_preference
      user = FlexMock.new
      user.should_receive(:get_preference).and_return { |key, domain|
        assert_equal('preference_key', key)
        assert_equal('domain', domain)
        nil
      }
      @persistence.should_receive(:find_entity, 1).times(1).and_return { user }
      res = nil
      res = @session.get_entity_preferences('name', ['preference_key'], 'domain')
      assert_equal({'preference_key' => nil}, res)
    end
    def test_get_entity_preferences__success
      user = FlexMock.new
      user.should_receive(:get_preference).and_return { |key, domain|
        assert_equal('preference_key', key)
        assert_equal('domain', domain)
        'value'
      }
      @persistence.should_receive(:find_entity, 1).times(1).and_return { user }
      res = nil
      res = @session.get_entity_preferences('name', ['preference_key'], 'domain')
      assert_equal({'preference_key' => 'value'}, res)
    end
    def test_set_entity_preference__no_user
      @persistence.should_receive(:find_entity).and_return { |name|
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
      @persistence.should_receive(:find_entity).and_return { |name|
        assert_equal('name', name)
        entity
      }
      entity.should_receive(:get_preference).and_return { |key, domain|
        assert_equal('key', key)
        value
      }
      entity.should_receive(:set_preference, 1).times(1).and_return { |key, val, domain|
        assert_equal('key', key)
        assert_equal('value', val)
        value = val
      }
      @persistence.should_receive(:save_entity, 1).times(1).and_return { |user| 
        assert_equal(entity, user) 
      }
      @session.set_entity_preference('name', 'key', 'value')
      @session.set_entity_preference('name', 'key', 'other')
    end
    def test_create_entity__success
      @config.should_receive(:digest).and_return { Digest::SHA256 }
      @persistence.should_receive(:find_entity, 1).times(1).and_return {}
      @persistence.should_receive(:add_entity, 1).times(1).and_return { |entity|
        assert_instance_of(Entity, entity)
        assert_equal('name', entity.name)
      }
      @session.create_entity('name', 'pass')
    end
    def test_create_entity__duplicate
      @persistence.should_receive(:find_entity, 1).times(1).and_return { 'something' }
      assert_raises(DuplicateNameError) {
        @session.create_entity('name')
      }
    end
    def test_allowed
      assert_equal(false, @session.allowed?('anything at all'))
    end
    def test_entity_allowed__no_user
      @persistence.should_receive(:find_entity, 1).times(1).and_return {}
      assert_raises(UnknownEntityError) {
        @session.entity_allowed?('name', 'action', 'key')
      }
    end
    def test_entity_allowed
      user = FlexMock.new
      expecteds = [['action1', nil], ['action2', 'key']]
      user.should_receive(:allowed?).and_return { |action, key|
        eact, ekey = expecteds.shift
        assert_equal(eact, action)
        assert_equal(ekey, key)
        action == 'action2'
      }
      @persistence.should_receive(:find_entity, 2).times(2).and_return { user }
      assert_equal(false, @session.entity_allowed?('name', 'action1'))
      assert_equal(true, @session.entity_allowed?('name', 'action2', 'key'))
    end
    def test_reset_entity_password__no_user
      @persistence.should_receive(:find_entity, 1).times(1).and_return {}
      assert_raises(UnknownEntityError) {
        @session.reset_entity_password('name', 'token', 'password')
      }
    end
    def test_reset_entity_password__no_token
      user = FlexMock.new
      user.should_receive(:allowed?).and_return { |action, token|
        assert_equal('reset_password', action)
        assert_equal('token', token)
        false
      }
      @persistence.should_receive(:find_entity, 1).times(1).and_return { user }
      assert_raises(NotPrivilegedError) {
        @session.reset_entity_password('name', 'token', 'password')
      }
    end
    def test_reset_entity_password__success
      user = FlexMock.new
      user.should_receive(:allowed?).and_return { |action, token|
        assert_equal('reset_password', action)
        assert_equal('token', token)
        true
      }
      user.should_receive(:passhash=, 1).times(1).and_return { |hash|
        assert_equal(Digest::SHA256.hexdigest('password'), hash)
      }
      user.should_receive(:revoke).and_return { |action, token|
        assert_equal('reset_password', action)
        assert_equal('token', token)
      }
      @config.should_receive(:digest).and_return { Digest::SHA256 }
      @persistence.should_receive(:find_entity, 1).times(1).and_return { user }
      @persistence.should_receive(:save_entity, 1).times(1).and_return { |entity|
        assert_equal(user, entity)
      }
      @session.reset_entity_password('name', 'token', 'password')
    end
    def test_grant__no_user
      @persistence.should_receive(:find_entity).and_return { |name|
        assert_equal('username', name)
        nil
      }
      assert_raises(UnknownEntityError) {
        @session.grant('username', 'action')
      }
    end
    def test_grant__success_key
      entity = FlexMock.new
      entity.should_receive(:grant).and_return { |action, key|
        assert_equal('action', action)
        assert_equal('key', key)
      }
      @persistence.should_receive(:find_entity).and_return { |name|
        assert_equal('username', name)
        entity
      }
      @persistence.should_receive(:save_entity, 1).times(1).and_return { |user| 
        assert_equal(entity, user) 
      }
      @session.grant('username', 'action', 'key')
    end
  end
  class TestEntitySession < Minitest::Test
    HexDigestSample = 'cleartext'
    def setup
      @config = FlexMock.new('config')
      @config.should_receive(:session_timeout).and_return { 0.5 }
      @config.should_receive(:token_lifetime).and_return { 0.2 }
      @digest = FlexMock.new('digest')
      @digest.should_receive(:hexdigest).and_return { HexDigestSample }
      @config.should_receive(:digest).by_default.and_return {@digest}
      @user = FlexMock.new('user')
      @user.should_receive(:set_token).and_return { 'set_token' }
      @user.should_receive(:name).and_return { 'name' }
      @persistence = FlexMock.new('persistence')
      @persistence.should_receive(:save_entity)
      @logger = FlexMock.new('logger')
      @logger.should_receive(:info).and_return {}
      @logger.should_receive(:debug).and_return {}
      @needle = FlexMock.new('needle')
      @needle.should_receive(:persistence).and_return { @persistence }
      @needle.should_receive(:config).and_return { @config }
      @needle.should_receive(:logger).and_return { @logger }
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
      @user.should_receive(:name).and_return { 'name' }
      assert_equal('name', @session.name)
    end
    def test_create_entity__not_allowed
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        false
      }
      assert_raises(NotPrivilegedError) { 
        @session.create_entity('name')
      }
    end
    def test_create_entity__success
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      @persistence.should_receive(:find_entity, 1).times(1).and_return {}
      @persistence.should_receive(:add_entity, 1).times(1).and_return { |entity|
        assert_instance_of(Entity, entity)
        assert_equal('name', entity.name)
      }
      @session.create_entity('name')
    end
    def test_generate_token
      assert_equal(false, @session.expired?)
      assert_equal(HexDigestSample, @session.generate_token)
    end
    def test_create_entity__duplicate
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      @persistence.should_receive(:find_entity, 1).times(1).and_return { 'something' }
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
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        false
      }
      assert_raises(NotPrivilegedError) { 
        @session.entities
      }
    end
    def test_entities__allowed
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      @persistence.should_receive(:entities).and_return { [] }
      assert_equal([], @session.entities)
    end
    def test_find_entity__not_allowed
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        false
      }
      assert_raises(NotPrivilegedError) {
        @session.find_entity('username')
      }
    end
    def test_find_entity__success
      @persistence.should_receive(:find_entity).and_return { |name|
        assert_equal('username', name)
        'found'
      }
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      assert_equal('found', @session.find_entity('username'))
    end
    def test_grant__not_allowed
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('grant', action)
        assert_equal('action', key)
        false
      }
      assert_raises(NotPrivilegedError) {
        @session.grant('username', 'action')
      }
    end
    def test_grant__no_user
      @persistence.should_receive(:find_entity).and_return { |name|
        assert_equal('username', name)
        nil
      }
      @user.should_receive(:allowed?).and_return { |action, key|
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
      entity.should_receive(:grant).and_return { |action, key|
        assert_equal('action', action)
        assert_equal(:everything, key)
      }
      @persistence.should_receive(:find_entity).and_return { |name|
        assert_equal('username', name)
        entity
      }
      @persistence.should_receive(:save_entity, 1).times(1).and_return { |user| 
        assert_equal(entity, user) 
      }
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('grant', action)
        assert_equal('action', key)
        true
      }
      @session.grant('username', 'action')
    end
    def test_grant__success_key
      entity = FlexMock.new
      entity.should_receive(:grant).and_return { |action, key|
        assert_equal('action', action)
        assert_equal('key', key)
      }
      @persistence.should_receive(:find_entity).and_return { |name|
        assert_equal('username', name)
        entity
      }
      @persistence.should_receive(:save_entity, 1).times(1).and_return { |user| 
        assert_equal(entity, user) 
      }
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('grant', action)
        assert_equal('action', key)
        true
      }
      @session.grant('username', 'action', 'key')
    end
    def test_valid__success
      @user.should_receive(:valid?).and_return { true }
      assert_equal(true, @session.valid?)
    end
    def test_valid__failure
      @user.should_receive(:valid?).and_return { false }
      assert_equal(false, @session.valid?)
    end
    def test_set_password__not_allowed
      @user.should_receive(:allowed?).and_return { |action, name|
        assert_equal('set_password', action)
        assert_equal('name', name)
        false
      }
      assert_raises(NotPrivilegedError) {
        @session.set_password('name', 'cleartext') 
      }
    end
    def test_set_password__no_user
      @persistence.should_receive(:find_entity).and_return { |name|
        assert_equal('username', name)
        nil
      }
      @user.should_receive(:allowed?).and_return { |action, name|
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
      @persistence.should_receive(:find_entity).and_return { |name|
        assert_equal('username', name)
        entity
      }
      @persistence.should_receive(:save_entity, 1).times(1).and_return { |user| 
        assert_equal(entity, user) 
      }
      @user.should_receive(:allowed?).and_return { |action, name|
        assert_equal('set_password', action)
        assert_equal('username', name)
        true
      }
      @config.should_receive(:digest).and_return { Digest::SHA256 }
      entity.should_receive(:passhash=).and_return { |hash|
        assert_equal(Digest::SHA256.hexdigest('cleartext'), hash)
      }
      @session.set_password('username', 'cleartext') 
    end
    def test_rename__not_allowed
      @user.should_receive(:allowed?).and_return { |action, name|
        assert_equal('edit', action)
        assert_equal('yus.entities', name)
        false
      }
      assert_raises(NotPrivilegedError) {
        @session.rename('oldname', 'newname') 
      }
    end
    def test_rename__no_user
      @persistence.should_receive(:find_entity).and_return { |name|
        assert_equal('oldname', name)
        nil
      }
      @user.should_receive(:allowed?).and_return { |action, name|
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
      @persistence.should_receive(:find_entity).and_return { |name|
        entities[name]
      }
      @user.should_receive(:allowed?).and_return { |action, name|
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
      entity.should_receive(:revoke, 1).times(1).and_return { |action, item|
        assert_equal('set_password', action)
        assert_equal('oldname', item)
      }
      entity.should_receive(:grant, 1).times(1).and_return { |action, item|
        assert_equal('set_password', action)
        assert_equal('newname', item)
      }
      entity.should_receive(:rename).and_return { |newname|
        assert_equal('newname', newname)
      }
      entities = {
        'oldname' => entity,
        'newname' => nil,
      }
      @persistence.should_receive(:find_entity).and_return { |name|
        entities[name]
      }
      @persistence.should_receive(:save_entity, 1).times(1).and_return { |user|
        assert_equal(entity, user)
      }
      @user.should_receive(:allowed?).and_return { |action, name|
        assert_equal('edit', action)
        assert_equal('yus.entities', name)
        true
      }
      @session.rename('oldname', 'newname') 
    end
    def test_revoke__not_allowed
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('grant', action)
        assert_equal('action', key)
        false
      }
      assert_raises(NotPrivilegedError) {
        @session.revoke('username', 'action')
      }
    end
    def test_revoke__no_user
      @persistence.should_receive(:find_entity).and_return { |name|
        assert_equal('username', name)
        nil
      }
      @user.should_receive(:allowed?).and_return { |action, key|
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
      entity.should_receive(:revoke).and_return { |action, key|
        assert_equal('action', action)
        assert_equal(:everything, key)
      }
      @persistence.should_receive(:find_entity).and_return { |name|
        assert_equal('username', name)
        entity
      }
      @persistence.should_receive(:save_entity, 1).times(1).and_return { |user| 
        assert_equal(entity, user) 
      }
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('grant', action)
        assert_equal('action', key)
        true
      }
      @session.revoke('username', 'action')
    end
    def test_revoke__success_key
      entity = FlexMock.new
      entity.should_receive(:revoke).and_return { |action, key|
        assert_equal('action', action)
        assert_equal('key', key)
      }
      @persistence.should_receive(:find_entity).and_return { |name|
        assert_equal('username', name)
        entity
      }
      @persistence.should_receive(:save_entity, 1).times(1).and_return { |user| 
        assert_equal(entity, user) 
      }
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('grant', action)
        assert_equal('action', key)
        true
      }
      @session.revoke('username', 'action', 'key')
    end
    def test_affiliate__not_allowed
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        false
      }
      assert_raises(NotPrivilegedError) { 
        @session.affiliate('name', 'group')
      }
    end
    def test_affiliate__no_user
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      @persistence.should_receive(:find_entity).and_return { |name|
        assert_equal('name', name)
        nil
      }
      assert_raises(UnknownEntityError) {
        @session.affiliate('name', 'group')
      }
    end
    def test_affiliate__no_group
      user = FlexMock.new
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      names = ['name', 'group']
      entities = [user, nil]
      @persistence.should_receive(:find_entity).and_return { |name|
        assert_equal(names.shift, name)
        entities.shift
      }
      assert_raises(UnknownEntityError) {
        @session.affiliate('name', 'group')
      }
    end
    def test_affiliate__success
      @persistence.should_receive(:save_entity).and_return {}
      user = FlexMock.new
      group = FlexMock.new
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      names = ['name', 'group']
      entities = [user, group]
      @persistence.should_receive(:find_entity).and_return { |name|
        assert_equal(names.shift, name)
        entities.shift
      }
      user.should_receive(:join, 1).times(1).and_return { |arg|
        assert_equal(group, arg)
      }
      @session.affiliate('name', 'group')
    end
    def test_disaffiliate__not_allowed
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        false
      }
      assert_raises(NotPrivilegedError) { 
        @session.disaffiliate('name', 'group')
      }
    end
    def test_disaffiliate__no_user
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      @persistence.should_receive(:find_entity).and_return { |name|
        assert_equal('name', name)
        nil
      }
      assert_raises(UnknownEntityError) {
        @session.disaffiliate('name', 'group')
      }
    end
    def test_disaffiliate__no_group
      user = FlexMock.new
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      names = ['name', 'group']
      entities = [user, nil]
      @persistence.should_receive(:find_entity).and_return { |name|
        assert_equal(names.shift, name)
        entities.shift
      }
      assert_raises(UnknownEntityError) {
        @session.disaffiliate('name', 'group')
      }
    end
    def test_disaffiliate__success
      @persistence.should_receive(:save_entity).and_return {}
      user = FlexMock.new
      group = FlexMock.new
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      names = ['name', 'group']
      entities = [user, group]
      @persistence.should_receive(:find_entity).and_return { |name|
        assert_equal(names.shift, name)
        entities.shift
      }
      user.should_receive(:leave, 1).times(1).and_return { |arg|
        assert_equal(group, arg)
      }
      @session.disaffiliate('name', 'group')
    end
    def test_set_entity_preference__not_allowed
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        false
      }
      assert_raises(NotPrivilegedError) { 
        @session.set_entity_preference('name', 'key', 'value')
      }
    end
    def test_set_entity_preference__no_user
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      @persistence.should_receive(:find_entity).and_return { |name|
        assert_equal('name', name)
        nil
      }
      assert_raises(UnknownEntityError) {
        @session.set_entity_preference('name', 'key', 'value')
      }
    end
    def test_set_entity_preference__success
      entity = FlexMock.new
      @user.should_receive(:allowed?).and_return { |action, key|
        assert_equal('edit', action)
        assert_equal('yus.entities', key)
        true
      }
      @persistence.should_receive(:find_entity).and_return { |name|
        assert_equal('name', name)
        entity
      }
      entity.should_receive(:set_preference, 1).times(1).and_return { |key, val|
        assert_equal('key', key)
        assert_equal('value', val)
      }
      @persistence.should_receive(:save_entity, 1).times(1).and_return { |user| 
        assert_equal(entity, user) 
      }
      @session.set_entity_preference('name', 'key', 'value')
    end
    def test_set_preference
      @user.should_receive(:set_preference, 1).times(1).and_return { |key, val, domain|
        assert_equal('key', key)
        assert_equal('value', val)
        assert_equal('domain', domain)
      }
      @persistence.should_receive(:save_entity, 1).times(1).and_return { |user| 
        assert_equal(@user, user) 
      }
      @session.set_preference('key', 'value')
    end
    def test_set_preferences
      @user.should_receive(:set_preference, 2).times(2).and_return { |key, val, domain| }
      @persistence.should_receive(:save_entity, 1).times(1).and_return { |user| 
        assert_equal(@user, user) 
      }
      @session.set_preferences({'key1' => 'value1', 'key2' => 'value2'})
    end
    def test_get_entity_preference__no_preference
      @user.should_receive(:get_preference).and_return { |key, domain|
        assert_equal('preference_key', key)
        assert_equal('domain', domain)
        nil
      }
      res = nil
      res = @session.get_preference('preference_key')
      assert_nil(res)
    end
    def test_get_entity_preference__success
      @user.should_receive(:get_preference).and_return { |key, domain|
        assert_equal('preference_key', key)
        assert_equal('domain', domain)
        'value'
      }
      res = nil
      res = @session.get_preference('preference_key')
      assert_equal('value', res)
    end
    def test_ping
      assert_equal(true, @session.ping)
    end
  end
  class TestRootSession < Minitest::Test
    def setup
      @config = FlexMock.new('config')
      @config.should_receive(:session_timeout).and_return { 0.5 }
      @needle = FlexMock.new('needle')
      @persistence = MockPersistence.new
      @logger = FlexMock.new('logger')
      @logger.should_receive(:info).and_return {}
      @needle.should_receive(:persistence).and_return { @persistence }
      @needle.should_receive(:logger).and_return { @logger }.by_default
      @needle.should_receive(:config).and_return { @config }.by_default
      @config.should_receive(:session_timeout).and_return { 0.5 }
      @session = RootSession.new(@needle)
    end
    def test_valid
      assert_equal(true, @session.valid?)
    end
    def test_allowed
      assert_equal(true, @session.allowed?('anything'))
    end
    def test_name
      @config.should_receive(:root_name).and_return { 'root_name' }
      assert_equal('root_name', @session.name)
    end
    def test_delete_entity
      entity_name = 'entity_name'
      entity = @session.create_entity(entity_name, 'entity_pass')
      assert_equal(entity, @session.find_entity(entity_name))
      @session.delete_entity(entity_name)
      assert_nil(@session.find_entity(entity_name))
    end
    def test_last_login
      entity_name = 'entity_name'
      entity = @session.create_entity(entity_name, 'entity_pass')
      domain = 'domain'
      entity.login(domain)
      assert_equal(entity, @session.find_entity(entity_name))
      #require 'pry'; binding.pry
      assert_in_delta(Time.now.to_f, @session.last_login(entity_name, domain).to_f)
    end
    def test_show
      assert_raises(UnknownEntityError) {
        @session.show('unkown_name')
      }
      entity_name = 'entity_name'
      @session.create_entity(entity_name, 'entity_pass')
      assert_kind_of(String, @session.show(entity_name))
      assert(@session.show(entity_name).index(entity_name) > 0)
    end

    def setup_for_dump
      assert_raises(UnknownEntityError) {
        @session.show('unkown_name')
      }
      @entity_name  = 'entity_name'
      entity_name2  = 'second_name'
      password      = 'entity_pass'
      groupname     = 'a_yus_group'
      @session.create_entity(@entity_name, password)
      @session.create_entity(entity_name2, password)
      @session.create_entity(groupname, password)
      assert_kind_of(String, @session.show(@entity_name))
      assert(@session.show(@entity_name).index(@entity_name) > 0)
      assert(@session.show(entity_name2).index(entity_name2) > 0)
      @session.affiliate(@entity_name, groupname)
      @session.grant(@entity_name, 'action', 'key')

      @needle = FlexMock.new('needle')
      @needle.should_receive(:persistence).and_return { @persistence }
      @needle.should_receive(:config).and_return { @config }
      @needle.should_receive(:logger).and_return { @logger }
    end

    def test_dump_to_named_yaml
      setup_for_dump
      tmpdir = File.expand_path(File.join(__FILE__, '../tmp'))
      outFile = File.join(tmpdir, 'yus_dump.yaml')
      assert(@session.dump_to_yaml(outFile))
      assert(File.exist?(outFile))
      assert(File.size(outFile) > 0)
      dump_content = IO.read(outFile)
      # puts "#{outFile} is #{File.size(outFile)} bytes lang and contains \n#{dump_content}"
      refute_nil(dump_content)
      refute_nil(dump_content.index(@entity_name))
      FileUtils.rm_rf(tmpdir)
      skip("Tests saving preferences")
    end

    def test_dump_to_default
      setup_for_dump
      assert(@session.dump_to_yaml)
      outFile = File.expand_path(File.join(__FILE__, '..', '..', 'data', 'yus_dump.yml'))
      assert(File.exist?(outFile), "outfile #{outFile} should exist")
      assert(File.size(outFile) > 0)
      dump_content = IO.read(outFile)
      # puts "#{outFile} is #{File.size(outFile)} bytes lang and contains \n#{dump_content}"
      refute_nil(dump_content)
      refute_nil(dump_content.index(@entity_name))
    end
  end
end
