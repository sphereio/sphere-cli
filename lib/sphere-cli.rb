require 'sphere-cli/version.rb'
require 'sphere-cli/api.rb'
require 'sphere-cli/account.rb'
require 'sphere-cli/catalogs.rb'
require 'sphere-cli/client.rb'
require 'sphere-cli/download.rb'
require 'sphere-cli/base.rb'
require 'sphere-cli/code.rb'
require 'sphere-cli/products.rb'
require 'sphere-cli/types.rb'
require 'sphere-cli/projects.rb'
require 'sphere-cli/folder.rb'
require 'sphere-cli/taxes.rb'
require 'sphere-cli/customergroups.rb'

# Add requires for other files you add to your project here, so
# you just need to require this one file in your bin file
require 'csv'
require 'set'
require 'json'
require 'open-uri'
include Sphere::CommandBase
include Sphere::API
