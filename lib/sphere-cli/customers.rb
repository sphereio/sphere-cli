module Sphere
  class Customers

    attr_reader :email2id
    attr_reader :id2version

    def initialize(sphere_project_key)
      @sphere_project_key = sphere_project_key
      @id2version = {}
      @email2id = {}
      @base_header = %w'id email firstName middleName lastName title defaultShippingAddressId defaultBillingAddressId isEmailVerified customerGroup'
      @address_header = %w'id title salutation firstName lastName streetName streetNumber additionalStreetInfo postalCode city region state country company department building apartment pOBox phone mobile email'
      set_language_attributes('')
    end

    def fetch_all
      start_time = Time.now
      printStatusLine "Fetching customers... "

      url = customers_list_url @sphere_project_key
      res = sphere.get url
      #sphere.ensure2XX "Problem on fetching customers for project with key '#{@sphere_project_key}'"
      @customers = parse_JSON res

      duration=Time.now - start_time
      printStatusLine "Fetching customers... Done in #{"%4.2f" % duration} seconds.\n"
    end

    def fill_maps
      @customers['results'].each { |g|
        id = g['id']
        @id2version[id] = g['version']
        @email2id[g['email']] = id
      }
    end

    def list
      fetch_all

      size = @customers['total']
      msg = "There #{pluralize size, 'is', 'are', true} #{pluralize size, 'customer'} in project with key '#{@sphere_project_key}'."
      puts msg
      msg
    end

    def export_to_csv
      start_time = Time.now
      printStatusLine "Exporting #{@count} customers... "

      fetch_all

      @max_addresses = 1
      rows = to_text
      header = @base_header + (@address_header * @max_addresses)

      puts header.to_csv
      rows.each { |r| puts r.to_csv }

      duration = Time.now - start_time
      printStatusLine "Exporting customers... Done, #{pluralize rows.size, 'customer'} in #{"%4.2f" % duration} seconds.\n"
      return header, rows
    end

    def to_text
      rows = []
      @customers['results'].each { |c|
        row = []
        @base_header.each { |h|
          next if h == 'addresses'
          if c['customerGroup']
            row << c['customerGroup']['id']
            next
          end
          if c[h]
            row << c[h]
          else
            row << ""
          end
        }
        addresses = c['addresses']
        @max_addresses = addresses.size if addresses.size > @max_addresses
        row = row + [""] * @address_header.size if addresses.empty?
        addresses.each { |a|
          @address_header.each { |h|
            if c[h]
              row << c[h]
            else
              row << ""
            end
          }
        }
        rows << row
      }
      rows
    end

    def import input
      start_time=Time.now

      fetch_all

      printStatusLine 'Importing customers... '
      csv_input = CSV.parse input
      data = validate_rows csv_input
      if not data[:errors].empty?
        data[:errors].each do |e|
          printMsg e
        end
        raise "Please correct the errors and try again."
      end
      creations = import_data data

      duration=Time.now - start_time
      printStatusLine "Importing customers... Done, #{pluralize creations, 'customer' } created in #{"%4.2f" % duration} seconds\n"
    end

    def validate_rows(csv_input)
      header, *rows = *csv_input

      h2i = {}
      header.each_with_index do |h,i|
        h2i[h] = i unless h2i[h]
      end

      data = { :errors => [], :rows => rows, :h2i => h2i}
      data
    end

    def import_data data
      data[:rows].each_with_index do |row, i|
        json = create_json_data row, data[:h2i]
        url = customer_create_url @sphere_project_key
        res = sphere.post url, json
        #sphere.ensure2XX "Problem on creating customer for project with key '#{@sphere_project_key}'"
      end
      data[:rows].size
    end

    def create_json_data(row, h2i)
      d = { :password => 'secret' }
      @base_header.each do |a|
        next if a == 'id'
        v = get_val row, a, h2i
        d[a] = v if v
      end
      d.to_json
    end

  end
end
