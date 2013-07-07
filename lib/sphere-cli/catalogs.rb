module Sphere

  class Catalogs

    attr_reader :duplicate_names
    attr_reader :name2id
    attr_reader :id2version
    attr_reader :fq_cat2id

    ACTIONS = [nil, '', 'create','changeName'] # TODO: add delete

    def initialize(project_key)
      @sphere_project_key = project_key
      @categories = []
      @fq_cat2id = {}
      @id2version = {}
      @duplicate_names = {}
      @name2id = {}
    end

    def list(global_options)
      res = sphere.get categories_list_url @sphere_project_key
      sphere.ensure2XX "Can't get categories for project with id '#{@sphere_project_key}'"
      performJSONOutput global_options, res do |data|
        if data.empty?
          puts "Project with key '#{@sphere_project_key}' has no categories."
          return
        end
        data.each do |c|
          puts "#{lang_val(c['name'])}: #{c['id']}"
        end
      end
    end

    def fetch_all
      start_time = Time.now
      printStatusLine "Downloading categories... "

      url = categories_list_url @sphere_project_key
      res = sphere.get url
      sphere.ensure2XX "Problem on fetching categories for project with key '#{@sphere_project_key}'"
      @categories = parse_JSON res

      duration=Time.now - start_time
      printStatusLine "Downloading categories... Done in #{"%5.2f" % duration} seconds.\n"
    end

    def export
      start_time = Time.now
      printStatusLine "Exporting #{@count} categories... "

      fetch_all

      @max_level = 1
      rows = to_text
      header = %w'action id rootCategory'
      header = header + (['category'] * (@max_level - 1))

      puts header.to_csv
      rows.each do |r|
        puts r.to_csv
      end

      duration = Time.now - start_time
      printStatusLine "Exporting categories... Done, #{pluralize(rows.size, 'catagory', 'categories')} in #{"%5.2f" % duration} seconds.\n"
      return header, rows
    end

    def to_text
      categories2text @categories, 0
    end
    def categories2text(cats, level)
      rows = []
      return rows unless cats
      @max_level = level if level > @max_level
      cats.each do |cat|
        row = [''] # id
        row << cat['id']
        row = row + ([''] * level) # put category in right column
        row << lang_val(cat['name'])
        rows << row
        rows = rows + categories2text(cat['subCategories'], level + 1)
      end
      rows
    end

    def fill_maps
      id2version_categories @categories, []
    end

    def id2version_categories(categories, parents)
      categories.each do |c|
        id = c['id']
        @id2version[id] = c['version']
        n = add_name2id(c, id)
        fq = parents + [n]
        @fq_cat2id[fq] = id
        id2version_categories c['subCategories'], fq
      end
    end

    def add_name2id(c, id)
      n = lang_val c['name']
      if @name2id.has_key? n
        if not @duplicate_names.has_key? n
          @duplicate_names[n] = [ @name2id[n] ]
        end
        @duplicate_names[n] << id
      end
      @name2id[n] = id
      n
    end

    def import(input)
      start_time=Time.now

      fetch_all

      printStatusLine 'Importing categories... '
      csv_input = CSV.parse input
      data = validate_rows csv_input
      if not data[:errors].empty?
        data[:errors].each do |e|
          printMsg e
        end
        raise "Please correct the errors and try again."
      end
      creations, updates = import_data data

      duration=Time.now - start_time
      printStatusLine "Importing categories... Done, #{pluralize creations, 'category', 'categories'} created and #{pluralize updates, 'category', 'categories'} updated and in #{"%5.2f" % duration} seconds\n"
    end

    def validate_rows(csv_input)
      header, *rows = *csv_input

      data = { :errors => [], :rows => [], :actions => [], :ids => [], :original_indexes => [] }

      root_index = -1
      h2i = {}
      header.each_with_index do |h,i|
        h2i[h] = i
        root_index = i if h == 'rootCategory'
      end
      data[:errors] << "[header row] There is no 'rootCategory' column." if root_index < 0
      data[:root_index] = root_index
      data[:errors] << '[row 2] There is no root category.' unless rows[0][root_index]

      fill_maps # build map of existing ids to versions

      row_index = 1
      rows.each_with_index do |row|
        row_index += 1
        action = h2i['action'] ? row[h2i['action']] : ''
        if not ACTIONS.include? action
          data[:errors] << "[row #{row_index}] Unknown action '#{action}'."
          next
        end
        id = row[h2i['id']] if h2i['id']
        action = 'create' if (action == nil or action.empty?) and id == nil # we assume to create if there is no action nor an id
        if action == 'create'
          if id
            data[:errors] << "[row #{row_index}] Create not possible: The sphere backend will assign an id to the element, please remove the id."
            next
          end
        elsif action == 'changeName'
          if id.nil?
            data[:errors] << "[row #{row_index}] Update not possible: Missing id."
            next
          elsif not @id2version.has_key? id
            data[:errors] << "[row #{row_index}] Update not possible: There is no existing item with id '#{id}'."
            next
          end
        end
        data[:actions] << action
        data[:ids] << id
        data[:original_indexes] << row_index
        data[:rows] << row
      end
      return data
    end

    def import_data(data)
      import_rows data[:rows], data[:actions], data[:ids], data[:root_index], data[:original_indexes]
    end

    def import_rows(rows, actions, ids, root_index, original_indexes)
      current_parents = []
      max = rows.size
      creations = 0
      updates = 0
      rows.each_with_index do |row, i|
        action = actions[i]
        id = ids[i]
        row.each_with_index do |cell, column_index|
          next if column_index < root_index
          if (cell == nil or cell.empty?)
            break unless current_parents[column_index] # category has no parent - go to next row
            next # cell has no content use next cell in same row
          end
          if action == 'create'
            creations += 1
            j = create_json_data cell, current_parents, column_index, root_index
            url = category_create_url @sphere_project_key
            res = sphere.post url, j
            sphere.ensure2XX "[row #{original_indexes[i]}] Problem on category creation"
            data = parse_JSON res
            id = data['id']
          elsif action == 'changeName'
            updates += 1
            j = update_json_data id, @id2version[id], cell
            url = category_update_url @sphere_project_key, id
            res = sphere.put url, j
            sphere.ensure2XX "[row #{original_indexes[i]}] Problem on changing category name"
          end
          current_parents = current_parents.first column_index  # erase parents deeper as my own level
          current_parents[column_index] = id
        end
        n = i + 1
        percents = (n * 100 / max).round
        printStatusLine "Importing categories... #{n} of #{max} (#{percents}% done)"
      end
      return creations, updates
    end

    def update_json_data(id, version, name)
      d = { :id => id, :version => version }
      d[:actions] = [{ :action => 'changeName', :name => lang_val(name) }]
      d.to_json
    end

    def create_json_data(name, current_parents, column_index, root_index)
      d = { :name => lang_val(name) }
      if column_index > root_index
        p_id = current_parents[column_index - 1]
        d[:parent] = { :id => p_id, :typeId => 'category' }
      end
      d.to_json
    end
  end

end
