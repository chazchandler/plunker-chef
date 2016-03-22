#
# Cookbook Name:: plunker
# Recipe:: www
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

require_recipe 'plunker::default'

basedir     = node['plunker']['www_root']
destdir     = File.join(basedir, 'plunker_www')

template '/etc/plunker/config.www.json' do
  source 'config.www.json.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
    embed_server_fqdn: node.fqdn,
    embed_server_port: node['plunker']['embed']['port'],
    www_server_fqdn: node.fqdn,
    www_server_port: node['plunker']['www']['port'],
    collab_server_fqdn: node.fqdn,
    collab_server_port: node['plunker']['collab']['port'],
    api_server_fqdn: node.fqdn,
    api_server_port: node['plunker']['api']['port'],
    run_server_fqdn: node.fqdn,
    run_server_port: node['plunker']['run']['port'],
    github_client_id: node['plunker']['github']['client_id'],
    github_client_secret: node['plunker']['github']['client_secret'],
    protocol: node['plunker']['protocol']
  })
  action :create
end

package 'apache2'

template '/etc/apache2/sites-available/plunker.conf' do
  source 'apache-vhost.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
    www_server_fqdn: node.fqdn,
    www_server_port: 8000,
    protocol: "http",
  })
  action :create
end

execute 'enable proxy_http' do
  command "a2enmod proxy_http"
end

execute 'enable plunker vhost' do
  command "a2ensite plunker"
end

service 'apache2' do
  action [ :enable, :start ]
end

include_recipe 'tarball::default'

username      = 'root'
tarball       = "plunker_www.tgz"
tmp_tb        = "/tmp/#{tarball}"

cookbook_file tmp_tb do
  source tarball
  # checksum sha256
  owner username
  group username
  mode '0644'
  action :create
end

tarball tmp_tb do
  destination basedir
  owner username
  group username
  umask 002
  action :extract
  not_if "test -d #{destdir}"
end

execute 'generate initd entry' do
  command "initd-forever -a #{destdir}/server.js"
end
