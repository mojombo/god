if $0 == __FILE__
  require File.join(File.dirname(__FILE__), *%w[.. lib god])
end

RAILS_ROOT = "/Users/tom/dev/gravatar2"

God.meddle do |god|
  god.interval = 5 # seconds
  
  god.watch do |w|
    w.name = "gravatar2-mongrel-3000"
    w.cwd = RAILS_ROOT
    w.start = "mongrel_rails start -P ./log/mongrel.pid -d"
    w.stop = "mongrel_rails stop -P ./log/mongrel.pid"
    w.grace = 10
  
    w.start_if do |r|
      r.condition(:process_not_running) do |c|
        c.pid_file = File.join(RAILS_ROOT, "log/mongrel.pid")
      end
    end
  end
end