module PoolParty
  module Console
    
    def load_pool(filename)
      PoolParty::Script.inflate open(filename).read
    end
    
  end
end

class Object
  include PoolParty::Console
end