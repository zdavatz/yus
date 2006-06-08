#!/usr/bin/env ruby
# Entity -- yus -- 29.05.2006 -- hwyss@ywesee.com

require 'yus/privilege'

module Yus
  class YusError < RuntimeError; end
  class CircularAffiliationError < YusError; end
  class AuthenticationError < YusError; end
  class DuplicateNameError < YusError; end
  class NotPrivilegedError < YusError; end
  class Entity
    attr_reader :name, :affiliations, :privileges
    attr_accessor :valid_from, :valid_until
    def initialize(name, valid_until=nil, valid_from=Time.now)
      @name = name.to_s
      @valid_until = valid_until
      @valid_from = valid_from
      @affiliations = []
      @privileges = Hash.new(false)
      @preferences = {}
    end
    def allowed?(action, item=:everything)
      valid? && ((privilege = @privileges[Entity.sanitize(action)]) \
        && privilege.granted?(item)) \
        || @affiliations.any? { |entity| entity.allowed?(action, item) }
    end
    def detect_circular_affiliation(entity)
      _detect_circular_affiliation(entity)
    rescue CircularAffiliationError => error
      error.message << ' <- "' << entity.name << '"'
      raise
    end
    def grant(action, item=:everything, expires=:never)
      action = Entity.sanitize(action)
      (@privileges[action] ||= Privilege.new).grant(item, expires)
    end
    def join(party)
      unless(@affiliations.include?(party))
        party.detect_circular_affiliation(self)
        @affiliations.push(party)
      end
    end
    def leave(party)
      @affiliations.delete(party)
    end
    def preference(key, domain='global')
      domain_preferences(domain)[key] || domain_preferences('global')[key]
    end
    def set_preference(key, value, domain='global')
      domain_preferences(domain)[key] = value
    end
    def valid?
      now = Time.now
      @valid_from < now && (!@valid_until || @valid_until > now)
    end
    def Entity.sanitize(term)
      term.to_s.downcase
    end
    protected
    def _detect_circular_affiliation(entity)
      if(@affiliations.include?(entity))
        raise CircularAffiliationError, 
          "circular affiliation detected: \"#{entity.name}\""
      end
      @affiliations.each { |aff| aff._detect_circular_affiliation(entity) }
    rescue CircularAffiliationError => error
      error.message << ' <- "' << @name << '"'
      raise
    end
    private
    def domain_preferences(domain)
      @preferences[domain] ||= {}
    end
  end
end
