module Sphere

  module API
    # ACCOUNT
    def login_url() '/login' end
    def logout_url() '/logout' end
    def signup_url() '/signup' end
    def account_details_url() '/api/users/me' end
    def account_delete_url() account_details_url end

    # ORGANIZATIONS
    def organizations_list_url() '/api/organizations' end
    def organization_details_url(org_id) "#{organizations_list_url}/#{org_id}" end

    # PROJECTS
    def projects_list_url() '/api/projects' end
    def project_create_url() projects_list_url end
    def project_sample_data_url(project_key) "/api/#{project_key}/sample-data" end
    def project_delete_url(project_key) "#{projects_list_url}/#{project_key}" end

    # COUNTRY and TAXES
    def project_add_countries_url(project_key) "#{projects_list_url}/#{project_key}" end
    def project_tax_categories_url(project_key) "/api/#{project_key}/tax-categories" end
    def project_add_tax_category(project_key) project_tax_categories_url project_key end
    def project_add_tax_rate_url(project_key, tax_category_id) "/api/#{project_key}/tax-categories/#{tax_category_id}" end

    # PRODUCT TYPES
    def product_types_list_url(project_key) "/api/#{project_key}/products/types" end
    def product_type_create_url(project_key) product_types_list_url project_key end
    def product_type_details_url(project_key, id) "/api/#{project_key}/products/types/#{id}" end
    def product_type_delete_url(project_key, id) product_type_details_url project_key, id end

    # CATALOGS
    def catalogs_list_url(project_key) "/api/#{project_key}/catalogs" end
    def catalog_create_url(project_key) catalogs_list_url project_key end

    # CATEGORIES
    def categories_list_url(project_key) "/api/#{project_key}/categories" end
    def category_create_url(project_key) categories_list_url project_key end
    def category_update_url(project_key, category_id) "/api/#{project_key}/categories/#{category_id}" end

    # PRODUCTS
    def products_list_url(project_key) "/api/#{project_key}/products" end
    def product_create_url(project_key) products_list_url project_key end
    def product_details_url(project_key, product_id) "/api/#{project_key}/products/#{product_id}" end
    def product_publish_url(project_key, product_id) product_details_url project_key, product_id end
    def variant_create_url(project_key, product_id)  product_details_url project_key, product_id end
    def product_images_url(project_key, product_id) "/api/#{project_key}/products/#{product_id}/images" end
    def product_images_import_url(project_key, product_id) "/api/#{project_key}/products/#{product_id}/import-images" end
    def product_delete_url(project_key, product_id, version) "#{product_details_url project_key, product_id}?version=#{version}" end

    # CUSTOMER GROUPS
    def customergroups_list_url(project_key) "/api/#{project_key}/customer-groups" end

    # CUSTOMERS
    def customers_list_url(project_key) "/api/#{project_key}/customers" end
    def customer_create_url(project_key) customers_list_url project_key end
  end

  module WWW
    def snowflake_template() '/cli/templates/snowflake.tgz' end
  end
end
