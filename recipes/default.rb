#
# Cookbook:: hashicat
# Recipe:: default
#
# Copyright:: 2020, The Authors, All Rights Reserved.

# Consul ACL token
# You could store this token in an encrypted databag, or HashiCorp Vault
consul_token = "YOURTOKENHERE"

# Install the Diplomat Gem https://github.com/WeAreFarmGeek/diplomat
# You could also use the built in Net::HTTP or HTTParty
chef_gem 'diplomat' do
  action :nothing
  compile_time false
end.run_action(:install)

require 'diplomat'

Diplomat.configure do |config|
  config.url = "http://127.0.0.1:8500"
  config.options = {headers: {"X-Consul-Token" => consul_token}}
end

# Install the apache web server
package 'apache2' do
  action :install
end

# Here we're fetching application configs from the Consul K/V store
# It's easy to store any kind of configuration data in Consul
p = Diplomat::Kv.get('placeholder')
w = Diplomat::Kv.get('width')
h = Diplomat::Kv.get('height')

# Here we wait until a service called "HashiCat Database" exists
# and that the service is in a passing state
ruby_block "wait_for_database" do
  block do
    service_passing = false
    until service_passing
      Chef::Log.info('sleeping 3 seconds until database is ready')
      sleep 3
      service = Diplomat::Health.new.service('HashiCat%20Database')[0]
      next unless service
      current_status = service.Checks[1]['Status']
      service_passing = current_status == 'passing'
    end
  end
end

# Get our database IP address
dbaddress = 'not set yet'
ruby_block 'get_db_address' do
  block do
    dbaddress = Diplomat::Service.get('HashiCat%20Database', :all)
  end
end

# Render the dynamic web app content
template '/var/www/html/index.html' do
  source 'index.html.erb'
  variables(
    lazy {
      {
        placeholder: p,
        height: h,
        width: w,
        dbaddress: dbaddress[0].Address
      }
    }
  )
  owner  'root'
  group  'root'
  mode   '0755'
end
