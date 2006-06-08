#!/usr/bin/env ruby
# Persistence::Og -- yus -- 31.05.2006 -- hwyss@ywesee.com

require 'og'
require 'yus/entity'
require 'yus/server'

module Yus
  module Persistence
    class Og
      def add_entity(entity)
        entity.save
      end
      def entities
        Entity.find_all
      end
      def find_entity(name)
        Entity.find_by_name(name)
      end
    end
  end
  class Privilege
    property :expiry_time, Time
    property :items, Hash
  end
  class Entity
    property :name, String
    property :valid_from, Time
    property :valid_until, Time
    property :preferences, Hash
    has_many :affiliations, Entity
    has_many :privileges, Privilege
  end
end
