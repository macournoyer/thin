namespace :deploy do
  task :site => %w(site:upload rdoc:upload)
  
  desc 'Deploy on code.macournoyer.com'
  task :alpha => %w(gem:upload deploy:site)
  
  desc 'Deploy on rubyforge'
  task :public => %w(gem:upload_rubyforge deploy:site)  
end
desc 'Deploy on all servers'
task :deploy => %w(deploy:alpha deploy:public)

def upload(file, to, options={})
  sh %{ssh macournoyer@code.macournoyer.com "rm -rf code.macournoyer.com/#{to}"} if options[:replace]
  sh %{scp -rq #{file} macournoyer@code.macournoyer.com:code.macournoyer.com/#{to}}
end
