module Sphere

  class Taxes

    attr_reader :duplicate_names
    attr_reader :name2id
    attr_reader :id2version

    def initialize(project_key)
      @project_key = project_key
      @id2version = {}
      @duplicate_names = {}
      @name2id = {}
      @taxes = []
    end

    def fetch_all
      res = sphere.get project_tax_categories_url @project_key
      #sphere.ensure2XX "Can't get tax categories of project with key '#{@project_key}'"
      @taxes = parse_JSON res
    end

    def fill_maps
      @taxes.each do |tax|
        id = tax['id']
        n = tax['name']
        @id2version[id] = tax['version']
        if @name2id.has_key? n
          @duplicate_names[n] = [ @name2id[n] ] if not @duplicate_names.has_key? id
          @duplicate_names[n] << id
        else
          @name2id[n] = id
        end
      end
    end

    def add_tax_category(name, desc)
      printStatusLine "Add tax category to project... "
      d = { :name => name, :description => desc}
      url = project_add_tax_category @project_key
      res = sphere.post url, d.to_json
      #sphere.ensure2XX "Add tax category named '#{name}' to project with key '#{@project_key}' failed"
      printMsg "Done"
      parse_JSON res
    end

    def add_tax_rate(tax_category_id, tax_category_version, name, amount, country, include_in_price)
      printStatusLine "Add tax rate... "
      t = { :name => name, :amount => amount, :country => country, :includedInPrice => include_in_price }
      d = { :id => tax_category_id, :version => tax_category_version, :actions => [{ :action => 'addTaxRate', :taxRate => t }] }
      url = project_add_tax_rate_url @project_key, tax_category_id
      res = sphere.put url, d.to_json
      #sphere.ensure2XX "Add tax rate named '#{name}' to tax category failed"
      printMsg "Done"
      parse_JSON res
    end

  end
end
