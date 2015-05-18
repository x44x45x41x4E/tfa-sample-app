# Set your full path to application.
app_path = "/home/deployer/apps/tfa-sample-app"

# Fill path to your app
working_directory "#{app_path}/current"

# Set master PID location
pid "/home/deployer/apps/tfa-sample-app/shared/tmp/pids/unicorn.pid"

# Log everything to one file
stderr_path "/home/deployer/apps/tfa-sample-app/shared/log/unicorn.error.log"
stdout_path "/home/deployer/apps/tfa-sample-app/shared/log/unicorn.access.log"

# Set unicorn options
worker_processes 2
preload_app true
timeout 180
listen "/home/deployer/apps/tfa-sample-app/shared/tmp/sockets/tfa-sample-app-unicorn.sock"

# Spawn unicorn master worker for user apps (group: apps)
user 'deployer', 'deployer'

# Should be 'production' by default, otherwise use other env
rails_env = ENV['RAILS_ENV'] || 'production'

GC.respond_to?(:copy_on_write_friendly=) &&
  GC.copy_on_write_friendly = true

before_exec do |server|
  ENV['BUNDLE_GEMFILE'] = "#{app_path}/current/Gemfile"
end

before_fork do |server, worker|
  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end

  # Before forking, kill the master process that belongs to the .oldbin PID.
  # This enables 0 downtime deploys.
  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
  end
end
