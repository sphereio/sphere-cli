module Sphere
  class CustomerGroups

    attr_reader :name2id
    attr_reader :id2version

    def initialize(sphere_project_key)
      @sphere_project_key = sphere_project_key
      @groups = []
      @id2version = {}
      @name2id = {}
    end

    def fetch_all
      start_time = Time.now
      printStatusLine "Downloading customer groups... "

      url = customergroups_list_url @sphere_project_key
      res = sphere.get url
      sphere.ensure2XX "Problem on fetching customer groups for project with key '#{@sphere_project_key}'"
      @groups = parse_JSON res

      duration=Time.now - start_time
      printStatusLine "Downloading customer groups... Done in #{"%4.2f" % duration} seconds.\n"
    end

    def fill_maps
      @groups.each do |g|
        id = g['id']
        @id2version[id] = g['version']
        @name2id[g['name']] = id
      end
    end

  end
end
