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
      @config.should_receive(:cleaner_interval).and_return { 100000000 }
      digest = FlexMock.new
      digest.should_receive(:hexdigest).and_return { |input| input }
      @config.should_receive(:digest).and_return { digest }
      @config.should_receive(:session_timeout).and_return { 0.5 }
      @config.should_receive(:root_name).and_return { 'admin' }
      @config.should_receive(:root_pass).and_return { 'admin' }
      @logger = FlexMock.new
      @logger.should_receive(:info)
      @logger.should_receive(:debug)
      @persistence = FlexMock.new
      @server = Server.new(@persistence, @config, @logger)
    end
    def test_authenticate__no_user
      @logger.should_receive(:warn).times(1)
      @persistence.should_receive(:find_entity).times(1)
      assert_raises(UnknownEntityError) {
        @server.authenticate('name', 'password')
      }
    end
    def test_authenticate__wrong_password
      @logger.should_receive(:warn).times(1)
      user = FlexMock.new
      user.should_receive(:authenticate).and_return { false }
      @persistence.should_receive(:find_entity).times(1).and_return { user }
      assert_raises(AuthenticationError) {
        @server.authenticate('name', 'password')
      }
    end
    def test_authenticate__success
      user = FlexMock.new
      user.should_receive(:authenticate).and_return { |pass|
        assert_equal('password', pass)
        true 
      }
      @persistence.should_receive(:find_entity).times(1).and_return { user }
      assert_nothing_raised {
        result = @server.authenticate('name', 'password')
        assert_equal(user, result)
      }
    end
    def test_autosession
      @server.autosession('domain') { |session|
        assert_instance_of(AutoSession, session)
      }
    end
    def test_login__success
      user = FlexMock.new
      user.should_receive(:authenticate).and_return { |pass|
        assert_equal('password', pass)
        true 
      }
      user.should_receive(:login)
      user.should_receive(:get_preference).and_return { |key, domain|
        {
          'session_timeout' =>  0.5, 
        }[key]
      }
      @persistence.should_receive(:find_entity).times(1).and_return { user }
      @persistence.should_receive(:save_entity).times(1) 
      assert_nothing_raised {
        session = @server.login('name', 'password', 'domain')
        assert_instance_of(EntitySession, session)
        assert_kind_of(DRb::DRbUndumped, session)
        assert_equal([session], @server.instance_variable_get('@sessions'))
      }
    end
    def test_logout
      needle = FlexMock.new
      needle.should_receive(:config).and_return { @config }
      @config.should_receive(:session_timeout).and_return { 200 }
      sessions = @server.instance_variable_get('@sessions')
      session = RootSession.new(needle)
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
      needle = FlexMock.new
      needle.should_receive(:config).and_return { @config }
      @config.should_receive(:session_timeout).and_return { 0.5 }
      sessions = @server.instance_variable_get('@sessions')
      session = RootSession.new(needle)
      sessions.push(session)
      sleep(1)
      @server.clean
      assert_equal([], sessions)
    end
  end
  class TestServerCleaner < Test::Unit::TestCase
    def test_autoclean
      config = FlexMock.new
      config.should_receive(:cleaner_interval).and_return { 0.5 }
      config.should_receive(:session_timeout).and_return { 0.5 }
      logger = FlexMock.new
      logger.should_receive(:info)
      logger.should_receive(:debug)
      needle = FlexMock.new
      needle.should_receive(:config).and_return { config }
      persistence = FlexMock.new
      server = Server.new(persistence, config, logger)
      sessions = server.instance_variable_get('@sessions')
      session = RootSession.new(needle)
      sessions.push(session)
      sleep(2)
      assert_equal([], sessions)
    end
  end
end
