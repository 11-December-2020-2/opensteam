#	openSteam - http://www.opensteam.net
#  Copyright (C) 2008  DiamondDogs Webconsulting
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; version 2 of the License.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License along
#  with this program; if not, write to the Free Software Foundation, Inc.,
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

class OpensteamGenerator < Rails::Generator::NamedBase

		
  attr_reader	:controller_class_name, :controller_file_name

							
  def initialize(runtime_args, runtime_options = {})
    super
				
    @controller_class_name = class_name + "Controller"
    @controller_file_name  = file_name + "_controller.rb"
	
  end

  require 'find'
  require 'yaml'

  def ffind_in_file(file,*strs)
   # file = File.join( File.dirname( __FILE__), "templates", file )
   # puts "'#{file}'"
    if File.file?( file )
      strs.each { |str| File.open(file).grep(/#{str}/) { |line| return :template  } }
      return :file
    end
    return :directory
  end

  
  def manifest
    record do |m|

      m.class_collisions class_path, class_name, "#{class_name}Test"
      m.class_collisions class_path, "#{controller_class_name}"

      Dir.chdir( File.dirname(__FILE__) )
      Find.find("./templates/"  ) do |f|
        ret = ffind_in_file(f, "<%%", "## TEMPLATE ##" )
        next if f.include?( '.svn' )
        f = f.gsub(/^\.\/templates\//,'')
        if f.include?( 'vendor' )
          ret == :directory ? m.send( ret, f ) : m.send( :file, f, f )
        else
          ret == :directory ? m.send( ret, f =~ /webshop/ ? f.gsub(/webshop/,"#{file_name}") : f ) : m.send(ret,f , f =~ /webshop/ ? f.gsub(/webshop/,"#{file_name}") : f, :collision => :force )
        end
      end

      administration_routes = <<END_OPENSTEAM_ROUTES
	  
 ## users / sessions (login/logout/register/signup)
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.register '/register', :controller => 'accounts', :action => 'create'
  map.signup '/signup', :controller => 'accounts', :action => 'new'
  map.activate '/activate/:activation_code', :controller => 'account', :action => 'activate'
  map.resource :session
  map.resource :account, :member => {
    :edit_password => :get,
    :update_password => :put,
    :activate => :get
  }
  
  ###
  
  # webshop
  map.resources :searches
  map.resource  :cart
  map.cart "/cart/*quantity", :controller => 'cart', :action => 'update', :conditions => { :method => :post }
  map.show_cart_item "/#{file_name}/show_cart_item/:id", :controller => '#{file_name}', :action => 'show_cart_item'
  map.shop_index "shop", :controller => '#{file_name}', :action => 'index'
  map.#{file_name} "#{file_name}", :controller => '#{file_name}', :action => 'index'
  map.connect "#{file_name}/:action/:type/:id", :controller => '#{file_name}'
  map.connect "#{file_name}/:action", :controller => '#{file_name}'
  map.connect "checkout/:action", :controller => 'checkout'
  map.connect "/store", :controller => '#{file_name}', :action => 'index'
  map.show_opensteam_product "#{file_name}/show/:type/:id", :controller => '#{file_name}', :action => 'show'
  map.opensteam_index "#{file_name}", :controller => '#{file_name}', :action => 'index'
  map.#{file_name}_index "#{file_name}", :controller => '#{file_name}', :action => 'index'
  map.administration "admin", :controller => 'admin', :action => 'index'
  map.admin_products "/admin/products", :controller => "admin", :action => "products"
  map.admin_properties "/admin/properties", :controller => "admin", :action => "properties"
  map.toggle_admin_payment_type "/admin/toggle_payment_type/:id", :controller => "admin", :action => "toggle_payment_type"



  ## namespaces

  # /admin
  map.admin "admin", :controller => 'admin', :action => 'index'
  map.namespace :admin do |admin|

    # /admin/catalog
    admin.namespace :catalog do |catalog|
      catalog.resources :products,    :only => [ :index ]
      catalog.resources :properties,  :only => [ :index ]
      catalog.resources :inventories
      catalog.resources :categories

      # dynamic products/properties resources
      Opensteam::Find.find_product_tables.collect(&:to_sym).each do |m|
        p = m.to_s.classify.constantize

        if p.column_names.include? p.inheritance_column
          p.find(:all).collect(&:type).collect(&:tableize).uniq.collect(&:to_sym).each do |mm|
            catalog.resources mm, :controller => m
          end
        end

        catalog.resources m do |p|
          p.resources :inventories, :requirements => { :product_type => m, :product_id => :id }
          Opensteam::Extension.product_extensions.each do |ext|
            p.resources ext, :requirements => { :product_type => m, :product_id => :id }
          end
#          :has_many => :inventories, :requirements => { :product_type => m }
        end
      end

      Opensteam::Find.find_property_tables.collect(&:to_sym).each do |m|
        catalog.resources m
      end

    end

    # /admin/sales
    admin.namespace :sales do |sales|
      sales.resources :orders, :has_many => [ :shipments, :invoices ]
      sales.resources :shipments
      sales.resources :invoices
    end

    # /admin/config
    admin.namespace :config do |config|
      config.resources :customers, :has_many => [ :orders ]
      config.resources :tax_zones
      config.resources :tax_groups
      config.resources :shipping_rate_groups

      [ :tax_zone, :tax_groups ].each do |c|
        config.connect c.to_s + "/filter", :controller => c.to_s, :action => 'filter', :conditions => { :method => :post }
      end

    end

    # /admin/system
    admin.namespace :system do |system|
      system.resources :users, :member => { :send_event => :put }
      system.resources :user_roles
      system.resources :mailers
      system.resources :configurations
      system.resources :quicksteams, :collection => { :order => :post }
    end

    admin.payment_types "payment_types", :controller => "admin", :action => 'payment_types'

  end


END_OPENSTEAM_ROUTES






      map_namespaceroutes( administration_routes )

      
      ### Patch application.rb ###
      sentinel = 'class ApplicationController < ActionController::Base'
      app_contr = 'app/controllers/application.rb'
      incl = "layout '#{file_name}'\n\n  public :render_to_string\n  include AuthenticatedSystem\n  include RoleRequirementSystem\n\n"
      gsub_file app_contr, /(#{Regexp.escape(sentinel)})/mi do |match|
        "#{match}\n  #{incl}"
      end
			
      
      ### Patch environment.rb ###
      sentinel = 'Rails::Initializer.run do |config|'
      incl = "require 'opensteam'"
      gsub_file 'config/environment.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
        "#{incl}\n\n#{match}\n"
      end

      
      incl = "
  config.after_initialize do
    Opensteam::Extension.initialize_extensions(config)
    ActiveMerchant::Billing::Base.mode = :test
  end"
      gsub_file 'config/environment.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
        "#{match}\n\n#{incl}\n"
      end
    

    end
  end
	
  protected
	
  def gsub_file(relative_destination, regexp, *args, &block)
    path = destination_path(relative_destination)
    content = File.read(path).gsub(regexp, *args, &block)
    File.open(path, 'wb') { |file| file.write(content) }
  end
		
		
  def map_namespaceroutes(str)
    ##
    ## just prints the str to routes.rb
    ## ToDo: implement actual namespace-method, like map_namspaceroutes( :space1 => { :space2 => "resourceA" } )
    ##
    logger.route str
    sentinel = 'ActionController::Routing::Routes.draw do |map|'
			
    unless options[:pretend]
      gsub_file 'config/routes.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
        "#{match}\n  #{str}"
      end
    end
  end
	
	
  # Override with your own usage banner.
  def banner
    "Usage: #{$0} opensteam ShopName"
  end

  def add_options!(opt)
    opt.separator ''
    opt.separator 'Options:'
    opt.on("--skip-timestamps",
      "Don't add timestamps to the migration files") { |v| options[:skip_timestamps] = v }
    opt.on("--skip-migration",
      "Don't generate a migration files") { |v| options[:skip_migration] = v }
  end

  def scaffold_views
    %w[ index show new edit ]
  end

  def model_name
    class_name.demodulize
  end
end
