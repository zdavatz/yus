#!/usr/bin/env ruby
# TestServer -- yus -- 01.06.2006 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'yus/server'
require 'flexmock'

module Yus
  class Server
    public :authenticate, :clean
  end
  class TestServer < Test::Unit::TestCase
    def setup
      @config = FlexMock.new
      @config.mock_handle(:cleaner_interval) { 100000000 }
      digest = FlexMock.new
      digest.mock_handle(:hexdigest) { |input| input }
      @config.mock_handle(:digest) { digest }
      @config.mock_handle(:session_timeout) { 0.5 }
      @config.mock_handle(:root_name) { 'admin' }
      @config.mock_handle(:root_pass) { 'admin' }
      @logger = FlexMock.new
      @logger.mock_handle(:info) {}
      @logger.mock_handle(:debug) {}
      @persistence = FlexMock.new
      @server = Server.new(@persistence, @config, @logger)
    end
    def test_authenticate__no_user
      @logger.mock_handle(:warn, 1) {}
      @persistence.mock_handle(:find_entity, 1) {}
      assert_raises(AuthenticationError) {
        @server.authenticate('name', 'password')
      }
      @persistence.mock_verify
      @logger.mock_verify
    end
    def test_authenticate__wrong_password
      @logger.mock_handle(:warn, 1) {}
      user = FlexMock.new
      user.mock_handle(:authenticate) { false }
      @persistence.mock_handle(:find_entity, 1) { user }
      assert_raises(AuthenticationError) {
        @server.authenticate('name', 'password')
      }
      @persistence.mock_verify
      @logger.mock_verify
    end
    def test_authenticate__success
      user = FlexMock.new
      user.mock_handle(:authenticate) { |pass|
        assert_equal('password', pass)
        true 
      }
      @persistence.mock_handle(:find_entity, 1) { user }
      assert_nothing_raised {
        result = @server.authenticate('name', 'password')
        assert_equal(user, result)
      }
      @persistence.mock_verify
    end
    def test_login__success
      user = FlexMock.new
      user.mock_handle(:authenticate) { |pass|
        assert_equal('password', pass)
        true 
      }
      user.mock_handle(:preference) { |key, domain|
        {
          'session_timeout' =>  0.5, 
        }[key]
      }
      @persistence.mock_handle(:find_entity, 1) { user }
      assert_nothing_raised {
        session = @server.login('name', 'password', 'domain')
        assert_instance_of(EntitySession, session)
        assert_kind_of(DRb::DRbUndumped, session)
        assert_equal([session], @server.instance_variable_get('@sessions'))
      }
      @persistence.mock_verify
    end
    def test_logout
      sessions = @server.instance_variable_get('@sessions')
      session = RootSession.new(nil, 200)
      sessions.push(session)
      @server.logout(session)
      assert_equal([], sessions)
    end
    def test_login__root
      session = @server.login('admin', 'admin', 'domain')
      assert_instance_of(RootSession, session)
    end
    def test_ping
      assert(@server.ping)
    end
    def test_clean
      sessions = @server.instance_variable_get('@sessions')
      session = RootSession.new(nil, 0.5)
      sessions.push(session)
      sleep(1)
      @server.clean
      assert_equal([], sessions)
    end
  end
  class TestServerCleaner < Test::Unit::TestCase
    def test_autoclean
      config = FlexMock.new
      config.mock_handle(:cleaner_interval) { 0.5 }
      logger = FlexMock.new
      logger.mock_handle(:info) {}
      logger.mock_handle(:debug) {}
      persistence = FlexMock.new
      server = Server.new(persistence, config, logger)
      sessions = server.instance_variable_get('@sessions')
      session = RootSession.new(nil, 0.5)
      sessions.push(session)
      sleep(2)
      assert_equal([], sessions)
    end
  end
end
