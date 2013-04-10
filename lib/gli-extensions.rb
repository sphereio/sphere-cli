module GLI

  module Extensions

    def load_config_files(global)
      file_config = {}
      cfgs = global[:config]
      return unless cfgs
      cfgs = [cfgs] unless cfgs.is_a? Array
      cfgs.each do |cfg|
        path = File.expand_path cfg
        begin
          next if not File.readable? path
          c = YAML.load IO.read path
          c = apply_to_aliases c, switches, flags
          file_config.merge! c
        rescue => e
          exit_now! "Unable to load config from '#{cfg}': #{e.message}"
        end
      end
      file_config
    end

    def apply_to_aliases(conf, switches, flags)
      # config loaded from yaml uses strings for keys
      new_conf = {}
      switches.each do |n,s|
        next unless s.aliases
        set_all s.aliases, new_conf, conf[n.to_s]
        s.aliases.each do |a|
          v = conf[a.to_s]
          set_all [n], new_conf, v
          set_all s.aliases, new_conf, v
        end
      end
      flags.each do |n,f|
        next unless f.aliases
        set_all f.aliases, new_conf, conf[n.to_s]
        f.aliases.each do |a|
          v = conf[a.to_s]
          set_all [n], new_conf, v
          set_all f.aliases, new_conf, v
        end
      end
      new_conf.merge! conf
    end

    def name2default(switches, flags)
      n2d = {}
      switches.each do |n,s|
        n2d[n] = s.default_value
        next unless s.aliases
        s.aliases.each do |a|
          n2d[a] = s.default_value
        end
      end
      flags.each do |n,f|
        n2d[n] = f.default_value
        next unless f.aliases
        f.aliases.each do |a|
          n2d[a] = f.default_value
        end
      end
      n2d
    end

    def set_all aliases, conf, value
      return if value.nil? # don't set nil values
      aliases.each do |a|
        # use symbol and string as key
        conf[a.to_sym] = value
        conf[a.to_s] = value
      end
    end

  end
end
