class MockPersistence
  attr_accessor :entities
  def initialize
    @entities = {}
  end
  def find_entity(name)
    @entities[name]
  end
  def add_entity(entity)
    @entities[entity.name] = entity
    entity
  end
  def delete_entity(name)
    @entities.delete(name)
  end
  def save_entity(entity)
    if(@entities[entity.name])
      @entities[entity.name] = entity
    else
      @entities.delete_if { |name, ent| ent.name == entity.name }
      add_entity(entity)
    end
  end
end
