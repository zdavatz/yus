#!/usr/bin/env ruby
# Server -- yus -- 31.05.2006 -- hwyss@ywesee.com

require 'drb'
require 'yus/entity'
require 'yus/session'

module Yus
  class Server
    def initialize(persistence, config, logger)
      @persistence = persistence
      @config = config
      @logger = logger
      @sessions = []
      run_cleaner
    end
    def login(name, password, domain)
      @logger.info(self.class) { 
        sprintf('Login attempt for %s from %s', name, domain)
      }
      hash = @config.digest.hexdigest(password)
      session = login_root(name, hash, domain) \
        || login_entity(name, hash, domain) # raises AuthenticationError
      @sessions.push(session)
      session
    end
    def logout(session)
      @logger.info(self.class) { 
        sprintf('Logout for %s', session)
      }
      @sessions.delete(session)
      if(session.respond_to?(:destroy!))
        session.destroy! 
      end
    end
    def ping
      true
    end
    private
    def authenticate(name, passhash)
      if((user = @persistence.find_entity(name)) && user.authenticate(passhash))
        @logger.info(self.class) { 
          sprintf('Authentication succeeded for %s', name)
        }
        user
      else
        @logger.warn(self.class) { 
          sprintf('Authentication failed for %s', name)
        }
        raise AuthenticationError, "Unknown user or wrong password"
      end
    end
    def clean
      @sessions.delete_if { |session| session.expired? }
    end
    def login_entity(name, passhash, domain)
      entity = authenticate(name, passhash)
      timeout = entity.preference("session_timeout", domain) \
        || @config.session_timeout
      EntitySession.new(@persistence, entity, domain, timeout)
    end
    def login_root(name, passhash, domain)
      if(name == @config.root_name && passhash == @config.root_pass)
        @logger.info(self.class) { 
          sprintf('Authentication succeeded for root: %s', name)
        }
        RootSession.new(@persistence, @config.session_timeout)
      end
    end
    def run_cleaner
      @cleaner = Thread.new {
        loop {
          sleep(@config.cleaner_interval)
          clean 
        }
      }
    end
  end
end
