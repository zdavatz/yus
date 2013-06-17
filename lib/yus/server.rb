#!/usr/bin/env ruby
# Server -- yus -- 31.05.2006 -- hwyss@ywesee.com

require 'drb'
require 'yus/entity'
require 'yus/session'
require 'needle'

VERSION = '1.0.1'

module Yus
  class Server
    def initialize(persistence, config, logger)
      @needle = Needle::Registry.new
      @needle.register(:persistence) { persistence }
      @needle.register(:config) { config }
      @needle.register(:logger) { logger }
      @sessions = []
      run_cleaner
    end
    def autosession(domain, &block)
      session = AutoSession.new(@needle, domain)
      block.call(session)
    end
    def login(name, password, domain)
      @needle.logger.info(self.class) { 
        sprintf('Login attempt for %s from %s', name, domain)
      }
      hash = @needle.config.digest.hexdigest(password.to_s)
      session = login_root(name, hash, domain) \
        || login_entity(name, hash, domain) # raises YusError
      @sessions.push(session)
      session
    end
    def login_token(name, token, domain)
      entity = authenticate_token(name, token)
      entity.login(domain)
      @needle.persistence.save_entity(entity)
      timeout = entity.get_preference("session_timeout", domain) \
        || @needle.config.session_timeout
      TokenSession.new(@needle, entity, domain)
    end
    def logout(session)
      @needle.logger.info(self.class) { 
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
      user = @needle.persistence.find_entity(name) \
        or raise UnknownEntityError, "Unknown Entity '#{name}'"
      user.authenticate(passhash) \
        or raise AuthenticationError, "Wrong password"
      @needle.logger.info(self.class) { 
        sprintf('Authentication succeeded for %s', name)
      }
      user
    rescue YusError
      @needle.logger.warn(self.class) { 
        sprintf('Authentication failed for %s', name)
      }
      raise
    end
    def authenticate_token(name, token)
      user = @needle.persistence.find_entity(name) \
        or raise UnknownEntityError, "Unknown Entity '#{name}'"
      user.authenticate_token(token) \
        or raise AuthenticationError, "Wrong token or token expired"
      @needle.logger.info(self.class) { 
        sprintf('Token-Authentication succeeded for %s', name)
      }
      user
    rescue YusError
      @needle.persistence.save_entity(user) if user
      @needle.logger.warn(self.class) { 
        sprintf('Token-Authentication failed for %s', name)
      }
      raise
    end
    def clean
      @sessions.delete_if { |session| session.expired? }
    end
    def login_entity(name, passhash, domain)
      entity = authenticate(name, passhash)
      entity.login(domain)
      @needle.persistence.save_entity(entity)
      timeout = entity.get_preference("session_timeout", domain) \
        || @needle.config.session_timeout
      EntitySession.new(@needle, entity, domain)
    end
    def login_root(name, passhash, domain)
      if(name == @needle.config.root_name \
         && passhash == @needle.config.root_pass)
        @needle.logger.info(self.class) { 
          sprintf('Authentication succeeded for root: %s', name)
        }
        RootSession.new(@needle)
      end
    end
    def run_cleaner
      @cleaner = Thread.new {
        loop {
          sleep(@needle.config.cleaner_interval)
          clean 
        }
      }
    end
  end
end
