#
# Cookbook:: hashicat
# Recipe:: default
#
# Copyright:: 2020, The Authors, All Rights Reserved.

chef_gem 'diplomat' do
  action :nothing
  compile_time false
end.run_action(:install)

require 'diplomat'

package 'apache2' do
  action :install
end

p = Diplomat::Kv.get('placeholder', { http_addr: 'http://127.0.0.1:8500', token: '046c3948-23a0-fde0-df55-19adf1e89774' })
w = Diplomat::Kv.get('width', { http_addr: 'http://127.0.0.1:8500', token: '046c3948-23a0-fde0-df55-19adf1e89774' })
h = Diplomat::Kv.get('height', { http_addr: 'http://127.0.0.1:8500', token: '046c3948-23a0-fde0-df55-19adf1e89774' })

template '/var/www/html/index.html' do
  source 'index.html.erb'
  variables({
    placeholder: p,
    height: h,
    width: w
  })
  owner  'root'
  group  'root'
  mode   '0755'
end
