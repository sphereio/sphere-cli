require 'parallel'
require 'ruby-progressbar'

module Sphere

  class Products

    ACTIONS = [nil, '', 'create', 'delete']
    NECESSARY_HEADERS = ['name', 'productType', 'variantId' ]
    LANGUAGE_HEADERS = ['name', 'description', 'slug' ]
    COLUMNS_IGNORED = ['masterVariant', 'id', 'version', 'productType', 'taxCategory', 'name', 'categories', 'variants', 'hasStagedChanges', 'published']
    VARIANT_COLUMNS_IGNORED = ['id', 'prices', 'images', 'attributes']
    VALUES_DELIM = ';'
    CATEGORY_CHILD_DELIM = '>'

    def initialize(project_key, global_options, tax_impl = Sphere::Taxes.new(project_key))
      @sphere_project_key = project_key
      @global_options = global_options
      @products = []
      @id2record = {}
      @id2product_type = {}
      @name2product_type = {}
      @number_products = 0
      @id2version = {}
      @cat_impl = Sphere::Catalogs.new project_key
      @tax_impl = tax_impl
      @group_impl = Sphere::CustomerGroups.new project_key
      set_language_attributes LANGUAGE_HEADERS
    end

    def list(options, global_options)
      project_key = get_project_key options
      res = sphere.get products_list_url project_key
      #sphere.ensure2XX "Can't get list of products"
      performJSONOutput global_options, res do |data|
        total = data['total']
        if total.nil? || total == 0
          puts "No products found in project with key '#{project_key}'."
          return
        end
        printMsg "There #{pluralize total, 'is', 'are', true} #{pluralize total, 'product'} in project with key '#{project_key}'."
      end
    end

    def create(args, options)
      printStatusLine 'Creating product... '
      project_key = get_project_key options
      input = validate_input_as_JSON args
      url = product_create_url project_key
      sphere.post url, input
      #sphere.ensure2XX "Can't create product."
      printMsg 'Done'
    end

    def fetch_all
      printStatusLine 'Downloading product types... '
      start_time = Time.now

      url = product_types_list_url (@sphere_project_key)
      res = sphere.get url
      #sphere.ensure2XX "Can't download product types"
      data = parse_JSON res
      data.each do |pt|
        @id2product_type[pt['id']] = pt
        @name2product_type[pt['name']] = pt
      end
      duration=Time.now - start_time
      printStatusLine "Downloading product types... Done, loaded #{pluralize data.size, 'product type'} in #{"%4.2f" % duration} seconds\n"

      printStatusLine 'Downloading products... '
      start_time = Time.now
      total = 0
      page_index = 0
      begin
        page_index += 1
        url = products_list_url (@sphere_project_key)
        url = url + "?page=#{page_index}" unless total == 0
        res = sphere.get url
        #sphere.ensure2XX "Can't download products"
        data = parse_JSON res
        data['results'].each do |p|
          @products << p
          @id2record[p['id']] = p
        end
        count = data['count']
        offset = data['offset']
        total = data['total']
        continue = offset + count < total
        percents = total == 0 ? 100 : ((offset + count) * 100 / total).round
        printStatusLine "Downloading products... #{offset + count} of #{total} (#{percents}%) done... "
      end while continue

      @number_products = total

      duration=Time.now - start_time
      printStatusLine "Downloading products... Done, loaded #{pluralize total, 'product'} in #{"%4.2f" % duration} seconds.\n"
    end

    def export_all
      printStatusLine "Processing #{pluralize @number_products, 'products'}... "
      start_time = Time.now

      if (@global_options[:'json-pretty'])
        # pretty JSON, iterate over individual records and output in indented pretty
        j = '['
        j << @products.map { |p| JSON.pretty_generate(p) }.join(',')
        j << ']'
        puts j
      elsif (@global_options[:'json-raw'])
        # raw JSON, iterate over individual records and output in raw
        puts "[#{@products.map { |p| JSON.generate(p) }.join(',')}]"
      else
        export_csv
      end

      duration = Time.now - start_time
      printStatusLine "Processing #{pluralize @number_products, 'products'}... Done in #{"%4.2f" % duration} seconds\n"
    end

    def delete_all
      if not @global_options[:force]
        puts 'WARNING: this action can not be undone'
        print 'Type the project key to verify: '
        verify_key = ask
        raise 'Cancelled, no action performed.' if verify_key != @sphere_project_key
      end

      fetch_all

      size = @products.size
      start_time = Time.now
      progress = ProgressBar.create(:title => "Deleting products", :total => size)
      Parallel.map(@products, :in_threads => @global_options[:para], :finish => lambda { |x,y| progress.increment }) do |p|
        d = publish_product_json_command p['id'], p['version'], true
        sphere.put product_publish_url(@sphere_project_key, p['id']), d, [200,400]
        sphere.delete product_delete_url(@sphere_project_key, p['id'], p['version'] + 1)
      end
      duration = Time.now - start_time
      printStatusLine "Deleting products... Done, deleted #{pluralize size, 'product'} in #{"%4.2f" % duration} seconds\n"
    end

    def export_csv
      base_columns = Set.new []
      variant_columns = Set.new []
      variant_attributes_columns = Set.new []
      @products.each do |p|
        p.each_key do |a|
          base_columns.add(a) unless COLUMNS_IGNORED.include?(a)
        end
        p['masterVariant'].each_key do |a|
          variant_columns.add(a) unless VARIANT_COLUMNS_IGNORED.include?(a)
        end
        p['masterVariant']['attributes'].each do |a|
          variant_attributes_columns.add(a['name'])
        end
      end

      header = %w'action id productType name'
      base_columns.each do |c|
        header << c
      end
      header << 'categories'
      header << 'variantId'
      variant_columns.each do |c|
        header << c
      end
      variant_attributes_columns.each do |c|
        header << c
      end
      header << 'images'

      rows = []
      @products.each do |p|
        row = [''] # action
        row << p['id'].to_s
        row << jsonValue(p, %w(productType id))
        row << lang_val(p['name'])
        base_columns.each do |c|
          v = p[c]
          if v.class == Hash
            row << lang_val(v)
          else
            row << v.to_s
          end
        end
        row << add_categories(p)
        row << jsonValue(p, %w(masterVariant id))
        variant_columns.each do |c|
          row << jsonValue(p, ['masterVariant', c])
        end
        variant_attributes_columns.each do |c|
          row << jsonValue(p, ['masterVariant', 'attributes', "[name=#{c}/value]"])
        end
        row << add_images(p['masterVariant'])
        rows << row
        p['variants'].each do |v|
          row = ['','','',''] # 'action,id,productType,name'
          base_columns.each do |c|
             row << ''
          end
          row << '' # categories
          row << jsonValue(v, %w(id))
          variant_columns.each do |c|
            row << jsonValue(v, [c])
          end
          variant_attributes_columns.each do |c|
            row << jsonValue(v, ['attributes', "[name=#{c}/value]"])
          end
          row << add_images(v)
          rows << row
        end
      end

      puts header.to_csv
      rows.each do |r|
        puts r.to_csv
      end
      return header, rows
    end

    def add_categories(item)
      cats = []
      item['categories'].each do |c|
        cats << c['id']
      end
      cats.join VALUES_DELIM
    end

    def add_images(item)
      images = []
      item['images'].each do |i|
        images << i['url']
      end
      images.join VALUES_DELIM
    end

    def import(input)
      printStatusLine 'Importing products... '
      start_time=Time.now

      parsed_rows = CSV.read input
      printStatusLine "Preprocessing products... #{pluralize (parsed_rows.size - 1), 'line'}"

      data = validate_rows parsed_rows
      if not data[:errors].empty?
        data[:errors].each do |e|
          printMsg e
        end
        exit_now! "Please correct the #{pluralize data[:errors].size, 'error'} and try again."
      end

      duration=Time.now - start_time
      printStatusLine "Preprocessing products... Done, processed #{pluralize (parsed_rows.size - 1), 'line'} in #{"%4.2f" % duration} seconds\n"
      printStatusLine 'Importing products... '

      total_products, total_variants = import_data data

      duration=Time.now - start_time
      printStatusLine "Importing products... Done, created #{pluralize total_products, 'product'} with #{pluralize total_variants, 'variant'} in #{"%4.2f" % duration} seconds\n"
    end

    def validate_rows(csv_input)
      header, *rows = *csv_input

      @cat_impl.fetch_all
      @cat_impl.fill_maps

      @tax_impl.fetch_all
      @tax_impl.fill_maps

      @group_impl.fetch_all
      @group_impl.fill_maps

      data = { :errors => [], :h2i => {}, :deletes => [], :rows => [], :actions => [], :original_indexes => [] }

      h2i = {}
      # build column/attribute indexes
      header.each_with_index do |h,i|
        data[:errors] << "Duplicate header column named '#{h}'." if h2i.has_key? h
        h2i[h] = i
        h2i["name"] = i if h == "name.#{language}"
      end
      data[:h2i] = h2i

      NECESSARY_HEADERS.each do |h|
        data[:errors] << "Column with header '#{h}' missing." unless h2i[h]
      end

      row_index = 1
      rows.each do |row|
        row_index += 1
        action = row[h2i['action']] if h2i['action']
        if not ACTIONS.include? action
          data[:errors] << "[row #{row_index}] Unknown action '#{action}'."
          next
        end
        id = row[h2i['id']] if h2i['id']
        action = 'create' if (action == nil or action.empty?) and id == nil # we assume to create if there is no action nor an id

        if action == 'create'
          if not is_variant? row, h2i
            pt = row[h2i['productType']] if h2i['productType']
            if pt.nil?
              data[:errors] << "[row #{row_index}] Create not possible: missing product type."
              next
            elsif (not @name2product_type.has_key? pt) and (not @id2product_type.has_key? pt)
              data[:errors] << "[row #{row_index}] Create not possible: product type with name/id '#{pt}' does not exist."
              next
            end
            # TODO: check for duplicate product types name
            # Store id in data when name is given
          end

        elsif action == 'delete'
          if id.nil?
            data[:errors] << "[row #{row_index}] Delete not possible: missing product id."
          elsif not @id2record.has_key? id
            data[:errors] << "[row #{row_index}] Delete not possible: product with id '#{id}' does not exist."
          else
            data[:deletes] << row
          end
          next
        end
        if not is_variant? row, h2i
          cat_ids = validate_categories row, row_index, h2i, data, @cat_impl
          if not cat_ids.nil?
            row[h2i['categories']] = cat_ids # Store the ids of the categories instead of their names.
          end
          tax_id = validate_tax_category row, row_index, h2i, data, @tax_impl
          row[h2i['tax']] = tax_id # Store the id of the tax category
        end

        json_prices = validate_prices row, row_index, h2i, data, @group_impl
        row[h2i['prices']] = json_prices if json_prices

        data[:actions] << action
        data[:original_indexes] << row_index
        data[:rows] << row
      end
      return data
    end

    def validate_categories(row, row_index, h2i, data, cat_impl)
      v = get_val row, 'categories', h2i
      return nil if v.nil?
      cats = v.index(VALUES_DELIM).nil? ? [ v ] : v.split(VALUES_DELIM)
      cat_ids = []
      cats.each do |c|
        if cat_impl.id2version.has_key? c
          cat_ids << c
          next
        end
        fq = c.split CATEGORY_CHILD_DELIM
        if fq.size > 1
          if cat_impl.fq_cat2id.has_key? fq
            cat_ids << cat_impl.fq_cat2id[fq]
            next
          end
        end
        if not cat_impl.name2id.has_key? c
          data[:errors] << "[row #{row_index}] Category with name '#{c}' does not exist."
          next
        end
        if cat_impl.duplicate_names.has_key? c
          data[:errors] << "[row #{row_index}] Category with name '#{c}' is not unique. Please use the category's id instead. One of #{cat_impl.duplicate_names[c].join ', '}"
          next
        end
        cat_ids << cat_impl.name2id[c]
      end
      return cat_ids.join VALUES_DELIM
    end

    def validate_tax_category(row, row_index, h2i, data, tax_impl)
      t = get_val row, 'tax', h2i
      data[:errors] << "[row #{row_index}] There is no tax defined." && return unless t
      return t if tax_impl.id2version.has_key? t
      data[:errors] << "[row #{row_index}] Tax category with name '#{t}' does not exist." && return unless tax_impl.name2id.has_key? t
      data[:errors] << "[row #{row_index}] Tax category with name '#{t}' is not unique. Please use the tax category's id instead. One of #{tax_impl.duplicate_names[t].join ', '}" && return if tax_impl.duplicate_names.has_key? t
      tax_impl.name2id[t]
    end

    def validate_prices(row, row_index, h2i, data, group_impl)
      d = { :prices => [] }
      # example: "DE-EUR 9999 B2B;USD 13900;AT-EUR 10999;YEN 100000 B2C"
      v = get_val row, 'prices', h2i
      return nil unless v
      v.split(';').each do |entry|
        p = {}
        data[:errors] << "[row #{row_index}] Invalid price value '#{v}' found." && next unless entry.include? ' '
        country_currency, centamount, customergroup = entry.split(' ')
        add_customer_group p, customergroup, row_index, data, group_impl
        currency = ''
        if country_currency.include? '-'
          country, currency = country_currency.split('-')
          p[:country] = country
        else
          currency = country_currency
        end
        p[:value] = money(currency, centamount)
        d[:prices] << p
      end
      d
    end

    def add_customer_group(price, customergroup, row_index, data, group_impl)
      return price unless customergroup
      g_id = ''
      if group_impl.id2version.has_key? customergroup
        g_id = customergroup
      else
        data[:errors] << "[row #{row_index}] Customer group with name '#{customergroup}' does not exist." && return unless group_impl.name2id.has_key? customergroup
        g_id = group_impl.name2id[customergroup]
      end
      price[:'customerGroup'] = { :typeId => "customer-group", :id => g_id }
      price
    end

    def delete_products(ids)
    end

    def import_data(data)
      total_products = 0
      total_variants = 0
      h2i = data[:h2i]

      current_product = nil
      current_images = nil
      current_variant_id = nil
      current_product_type = nil
      row_start = 0
      product_data = []
      max = data[:rows].size
      data[:rows].each_with_index do |row, i|
        row_index = data[:original_indexes][i]
        if is_variant? row, h2i
          current_product[:variants] << variant_json_data(row, h2i, current_product_type)
          current_variant_id += 1
          imgs = image_json_data row, h2i, current_variant_id, row_index
          current_images[:images] += imgs
          total_variants += 1
        else # new product
          if i > 0
            d = { :p_data => current_product, :i_data => current_images }
            product_data << d
          end

          t = get_val row, 'productType', h2i
          current_product_type = @name2product_type[t] || @id2product_type[t]
          current_product = create_product_json_data row, h2i, current_product_type
          current_images = import_image_json_data row, h2i, row_index
          current_variant_id = 1
          row_start = row_index
        end
        n = i + 1
        percents = (n * 100 / max).round
        printStatusLine "Transforming products... line #{n} of #{max} (#{percents}% done)"
      end
      d = { :p_data => current_product, :i_data => current_images }
      product_data << d

      product_ids = []
      progress = ProgressBar.create(:title => "Importing products", :total => product_data.size)
      Parallel.each(product_data, :in_threads => @global_options[:para], :finish => lambda { |x,y| progress.increment }) do |data|
        res = sphere.post product_create_url(@sphere_project_key), data[:p_data].to_json
        j = parse_JSON res
        id = j['id']
        product_ids << id
        data[:i_data][:id] = id # store image id for later image request
      end

      progress = ProgressBar.create(:title => "Importing images", :total => product_data.size)
      Parallel.each(product_data, :in_threads => 1, :finish => lambda { |x,y| progress.increment }) do |data|
        img = data[:i_data]
        if img[:images].size > 0
          id = img[:id]
          img[:images].each_slice(1) do | images|
            d = { :id => id, :images => images }
            sphere.post product_images_import_url(@sphere_project_key, id), d.to_json
          end
        end
      end

      progress = ProgressBar.create(:title => "Publishing products", :total => product_ids.size)
      Parallel.each(product_ids, :in_threads => @global_options[:para], :finish => lambda { |x,y| progress.increment }) do |id|
        d = publish_product_json_command id, 1
        sphere.put product_publish_url(@sphere_project_key, id), d
        #sphere.ensure2XX "Can't publish product with id '#{id}'"
      end

      return product_data.size, total_variants
    end

    # TODO: Allow user to upload local files as images (via command line option)
    #prod_version = upload_image row, h2i, current_product_id, row_index
    #@id2version[current_product_id] = prod_version unless prod_version.nil?
    def upload_image(row, h2i, product_id, row_index)
      url = get_val row, 'images', h2i
      return nil unless url
      res = sphere.post_image product_images_url(@sphere_project_key, product_id), url
      raise "[row #{row_index}] Problems on image upload: '#{url}' - server returned with code '#{res.code}':\n  #{res.body}" if res == nil or res.code != "200"
      j = parse_JSON res.body
      j['version'] # The method returns the latest version of the product.
    end

    def is_variant?(row, h2i)
      pt = get_val row, 'productType', h2i
      v = get_val row, 'variantId', h2i
      return true if (pt.nil? or pt.empty?) and not v.empty? and v.to_i > 1
    end

    def create_product_json_data(product, h2i, product_type)
      name = get_val product, 'name', h2i
      slug = get_val product, 'slug', h2i
      slug = slugify name unless slug
      sku = get_val product, 'sku', h2i
      desc = get_val product, 'description', h2i
      cats = categories product, h2i
      tax_id = get_val product, 'tax', h2i

      d = {}
      d[:productType] = { :id => product_type['id'], :typeId => 'product-type' }
      d[:taxCategory] = { :id => tax_id, :typeId => 'tax-category' }
      d[:name] = name
      d[:slug] = slug
      d[:description] = desc if desc
      d.merge! cats if cats
      d[:masterVariant] = variant_json_data(product, h2i, product_type)
      d[:variants] = []
      d
    end

    def variant_json_data(variant, h2i, product_type)
      sku = get_val variant, 'sku', h2i
      price = get_val variant, 'prices', h2i
      d = {}
      d[:sku] = sku if sku
      d.merge! price if price
      d.merge! variant_attributes(variant, h2i, product_type)
    end

    def import_image_json_data(row, h2i, row_index)
      imgs = image_json_data(row, h2i, 1, row_index)
      d = { :images => imgs }
    end

    def image_json_data(row, h2i, variant_id, row_index)
      images = get_val row, 'images', h2i
      imageLabels = get_val row, 'imageLabels', h2i
      return [] unless images
      ignoreLabel = false
      ignoreLabel = true unless imageLabels
      urls = images.split VALUES_DELIM
      unless ignoreLabel
        labels = imageLabels.split VALUES_DELIM
        if urls.size != labels.size
          raise "[row #{row_index}] Number of image labels do not correspond to number of images"
        end
      end
      data = []
      urls.each_with_index do |url, index|
        img = { :variantId => variant_id, :url => url }
        unless ignoreLabel
          img[:label] = labels[index]
          img[:filename] = labels[index]
        end
        data << img
      end
      data
    end

    def publish_product_json_command(product_id, product_version, unpublish=false)
      d = { :id => product_id, :version => product_version }
      d[:actions] = [{ :action => "#{'un' if unpublish }publish" }]
      d.to_json
    end

    def money(currency, price)
      d = { :currencyCode => currency, :centAmount => price.to_i }
    end

    def categories(row, h2i)
      d = { :categories => [] }
      v = get_val row, 'categories', h2i
      return nil if v.nil?
      cat_ids = v.index(VALUES_DELIM).nil? ? [v] : v.split(VALUES_DELIM)
      cat_ids.each do |id|
        d[:categories] << { :typeId => 'category', :id => id }
      end
      d
    end

    def variant_attributes(row, h2i, product_type)
      d = { :attributes => [] }
      return d if product_type['attributes'].empty?
      product_type['attributes'].each do |a|
        n = a['name']
        value = get_typed_val row, n, h2i, a['type']
        next if value.nil?
        d[:attributes] << { :name => n, :value => value }
      end
      d
    end

    def get_typed_val(row, attr_name, h2i, attr_type)
      v = get_val row, attr_name, h2i
      return nil if v.nil?
      return v.to_i if attr_type == 'number'
      if attr_type == 'money'
        c, p = v.split ' '
        return money c, p
      end
      v
    end

  end
end
