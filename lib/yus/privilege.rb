#!/usr/bin/env ruby
# Privilege -- yus -- 31.05.2006 -- hwyss@ywesee.com

module Yus
  class Privilege
    attr_writer :expiry_time
    def initialize
      @items = {}
    end
    def expiry_time(item=:everything)
      if(time = [@items[item], @items[:everything]].compact.max)
        time if time.is_a?(Time)
      else
        raise NotPrivilegedError
      end
    end
    def grant(item, expiry_time=:never)
      @items.store(item, expiry_time)
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
        item = item.to_s.dup
        if(item[-1] != ?*)
          while(!item.empty?)
            item.slice!(/[^.]*$/)
            if(granted?(item + "*"))
              return true
            end
            item.chop!
          end
        end
        false
      end
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
