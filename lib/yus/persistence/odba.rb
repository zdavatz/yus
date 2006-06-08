#!/usr/bin/env ruby
# Persistence::ODBA -- yus -- 31.05.2006 -- hwyss@ywesee.com

require 'odba'
require 'yus/entity'
require 'yus/server'

module Yus
  module Persistence
    class Odba
      def initialize
        @entities = ODBA.cache.fetch_named('entities', self) { Hash.new }
      end
      def add_entity(entity)
        @entities.store(Entity.sanitize(entity.name), entity)
        entity.odba_store
        @entities.odba_store
      end
      def entities
        @entities.values
      end
      def find_entity(name)
        @entities[Entity.sanitize(name)]
      end
    end
  end
  class Entity
    include ODBA::Persistable
    ODBA_SERIALIZABLE = ['@privileges', '@preferences']
  end
end
