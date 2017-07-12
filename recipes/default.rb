#
# Cookbook Name:: sym_convert
# Recipe:: default
#
# Copyright (c) 2017 The Authors, All Rights Reserved.
#

#
# Variables
#
node_name = Chef.run_context.node.name.to_s
mail_to   = 'cbeleno@redsis.com'
new_file  = "C:\\Eva\\sym-localidad\\engines\\tolima-00#{node_name}.properties"
last_file = "C:\\Eva\\sym-localidad\\engines\\localidad-00#{node_name}.properties"

#
# Main process
#
batch 'Stop SymmetricsDS' do
  cwd 'C:\Eva\sym-localidad\bin'
  code 'sym_service stop'
end

batch 'Uninstall symadmin' do
  cwd 'C:\Eva\sym-localidad\bin'
  code 'symadmin uninstall'
end

ruby_block 'New Engine File' do
  block do
    file_content = File.read(last_file)
    file_content = file_content.gsub(/engine.name=localidad/,'engine.name=tolima')
    file_content = file_content.gsub(/group.id=localidad/,'group.id=tolima')
    File.open(new_file, 'w') { |file| file.write file_content }
  end
end

file last_file do
  action :delete
end

batch 'Start SymmetricsDS' do
  cwd 'C:\Eva\sym-localidad\bin'
  code 'sym_service start'
end

#
# Notification
#
ruby_block 'Notification' do
  block do
    f = Url.fetch 'http://localhost:8080/Eva/apilocalidad/version'
    file_content = File.read(new_file)

    subject = "Chef Configure SymmetricsDS on Node #{f["codLocalidad"]}"
    message = "Successful configuration in #{f["codLocalidad"]} #{f["descripLocalidad"]}"
    message << "\n\nContent of tolima-00#{node_name}.properties file:\n#{file_content}"

    Chef::Log.info(message)
    Tool.attached_email(mail_to, subject, message)
  end
end
