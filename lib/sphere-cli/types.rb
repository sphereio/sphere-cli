module Sphere

  class ProductTypes

    def list(options, global_options)
      project_key = get_project_key options
      res = sphere.get product_types_list_url project_key
      sphere.ensure2XX "Can't get list of product types for project with key '#{project_key}'"
      performJSONOutput global_options, res do |data|
        if data.empty?
          puts "The project with key '#{project_key}' has no product types."
          return
        end
        data.each do |pt|
          puts "#{pt['name']}: #{pt['description']} (id: #{pt['id']})"
        end
      end
    end

    def create args, options
      printStatusLine 'Creating product type... '
      project_key = get_project_key options
      input = validate_input_as_JSON args
      sphere.post product_type_create_url(project_key), input
      sphere.ensure2XX "Can't create product type"
      printMsg 'Done'
    end

    def details(args, options, global_options)
      project_key = get_project_key options
      id = get_input args, 'No product type id provided.'
      url = product_type_details_url project_key, id
      res = sphere.get url
      sphere.ensure2XX "Can't get details for product type with id '#{id}' from project with key '#{project_key}'"
      performJSONOutput global_options, res do |data|
        puts "id: #{data['id']}"
        puts "Name: #{data['name']}"
        puts "Description: #{data['description']}"
        puts "Attributes (#{data['attributes'].length})"
        data['attributes'].each do |attr|
          puts "  #{attr['name']}: #{attr['type']}"
        end
      end

    end

    def delete(args, options, global_options)
      printStatusLine 'Deleting product type... '
      project_key = get_project_key options
      id = get_input args, 'No product type id provided.'
      res = sphere.delete product_type_delete_url project_key, id
      sphere.ensure2XX "Failed to delete product type with id '#{id}' from project with key '#{project_key}'"
      printMsg 'Done'
    end

  end
end
