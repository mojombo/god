# This is the actual config file used to keep the mongrels of
# gravatar.com running.

RAILS_ROOT = "/var/www/gravatar2/current"

God.meddle do |god|
  god.interval = 30 # seconds

  %w{8200 8201 8202}.each do |port|
    god.watch do |w|
      w.name = "gravatar2-mongrel-#{port}"
      w.cwd = RAILS_ROOT
      w.start = "mongrel_rails cluster::start --only #{port}"
      w.stop = "mongrel_rails cluster::stop --only #{port}"

      w.start_if do |start|
        start.condition(:process_not_running) do |c|
          c.pid_file = File.join(RAILS_ROOT, "log/mongrel.#{port}.pid")
        end
      end
    end
  end
end