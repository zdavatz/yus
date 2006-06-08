#!/usr/bin/env ruby
# Privilege -- yus -- 31.05.2006 -- hwyss@ywesee.com

module Yus
  class Privilege
    attr_accessor :expiry_time
    def initialize
      @items = {}
    end
    def granted?(item)
      if(expiry_time = @items[item])
        case expiry_time
        when Time
          Time.now < expiry_time
        else
          true
        end
      elsif(@items.include?(:everything))
        # check time
        granted?(:everything)
      else
        false
      end
    end
    def grant(item, expiry_time=:never)
      @items.store(item, expiry_time)
    end
    def revoke(item, expiry_time=nil)
      case expiry_time
      when Time
        @items.store(item, expiry_time)
      else
        @items.delete(item)
      end
    end
  end
end
