#!/usr/bin/env ruby
# Session -- yus -- 02.06.2006 -- hwyss@ywesee.com

require 'drb'
require 'thread'
require 'yus/entity'

module Yus
  class Session
    include DRb::DRbUndumped
    def initialize(persistence, timeout)
      @persistence = persistence
      @timeout = timeout
      @mutex = Mutex.new
      touch!
    end
    def create_entity(name, valid_until=nil, valid_from=Time.now)
      unless(allowed?('edit', 'yus.entities'))
        raise NotPrivilegedError, 'You are not privileged to edit Entities'
      end
      @mutex.synchronize { 
        if(find_entity(name))
          raise DuplicateNameError, "Duplicate name: #{name}"
        end
        entity = Entity.new(name, valid_until, valid_from)
        @persistence.add_entity(entity)
      }
      touch!
    end
    def delete_entity(name)
      unless(allowed?('edit', 'yus.entities'))
        raise NotPrivilegedError, 'You are not privileged to edit Entities'
      end
      touch!
    end
    def destroy!
      @persistence = @user = nil
      @timeout = -1
    end
    def expired?
      Time.now > (@last_access + @timeout)
    end
    def entities
      unless(allowed?('edit', 'yus.entities'))
        raise NotPrivilegedError, 'You are not privileged to edit Entities'
      end
      touch!
      @persistence.entities
    end
    def find_entity(name)
      unless(allowed?('edit', 'yus.entities'))
        raise NotPrivilegedError, 'You are not privileged to edit Entities'
      end
      touch!
      @persistence.find_entity(name)
    end
    private
    def touch!
      @last_access = Time.now
    end
  end
  class EntitySession < Session
    def initialize(persistence, user, domain, timeout)
      @user = user
      @domain = domain
      super(persistence, timeout)
    end
    def allowed?(*args)
      @user.allowed?(*args)
    end
    def valid?
      @user.valid?
    end
  end
  class RootSession < Session
    def allowed?(*args)
      true
    end
    def valid?
      true
    end
  end
end
