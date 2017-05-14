# encoding: UTF-8

# Add to_bool method to String class; this makes source more readable
class String
    def to_bool
        return true  if self =~ (/^(true|t|yes|y|1)$/i)
        return false if self.empty? || self =~ (/^(false|f|no|n|0)$/i)
        
        raise ArgumentError.new "invalid value: #{self}"
    end  
end
