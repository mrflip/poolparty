require ::File.dirname(__FILE__)+"/../aska/aska.rb"
require ::File.dirname(__FILE__)+"/../../poolparty/lite.rb"

module Butterfly
  class StatsMonitorAdaptor < AdaptorBase
    attr_reader :stats
    
    def initialize(o={})
      super
      @cloud = JSON.parse( open(o[:clouds_json_file]).read ) rescue {"options" => 
                                                                      {"rules" => {"expand" => PoolParty::Default.expand_when, 
                                                                                    "contract" => PoolParty::Default.contract_when
                                                                                  }}}
      # Our cloud.options.rules looks like
      #  {"expand_when" => "load > 0.9", "contract_when" => "load < 0.4"}
      # We set these as rules on ourselves so we can use aska to parse the rules
      # So later, we can call vote_rules on ourself and we'll get back Aska::Rule(s)
      # which we'll call valid_rule? for each Rule and return the result
      @cloud["options"]["rules"].each do |name,rul|
        r = Aska::Rule.new(rul)
        rule(name) << r
      end
    end
    
    def get(req, resp)
      begin
        if !req.params || req.params.empty?
          default_stats.to_json
        else
          stats[req.params[0].to_sym] ||= self.send(req.params[0])
          stats[req.params[0].to_sym]
        end
      rescue Exception => e
        resp.fail!
        "Error: #{e}"
      end 
    end
    
    def rules
      @rules ||= {}
    end
    
    def rule(name)
      rules[name] ||= []
    end
    
    def default_stats
      %w(load nominations).each do |var|
        stats[var.to_sym] ||= self.send(var.to_sym)
      end
      stats
    end

    def stats
      @stats ||= {}
    end
    
    def load
      %x{"uptime"}.split[-3].to_f
    end
    
    def instances
      res = %x{"server-list-active names"}.split(" ")
      res
    end
    
    def can_expand?
      instances.size < max_instances
    end
    
    def can_contract?
      instances.size > min_instances
    end
    
    def min_instances
      (@cloud["options"]["minimum_instances"] || PoolParty::Default.minimum_instances).to_i
    end
    
    def max_instances
      (@cloud["options"]["maximum_instances"] || PoolParty::Default.maximum_instances).to_i
    end
    
    def nominations
      load = stats[:load] ||= self.send(:load)
      stats[:nominations] ||= rules.collect do |k,cld_rules|
        t = cld_rules.collect do |r|
          # If the comparison works
          if self.send(r.key.to_sym).to_f.send(r.comparison, r.var.to_f)
            # if we are facing an expansion rule
            if k =~ /expand/
              k if can_expand?
            # if we are facing a contraction rule
            elsif k =~ /contract/
              k if can_contract?
            else
              k
            end
          end
        end.compact
      end.flatten.compact
    end
  
    def reload_data!
      super
      @stats = {}
    end
  end
end