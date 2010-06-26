# God::Contacts::Email.message_settings = {
#   :from => 'support@gravatar.com'
# }
# 
# God::Contacts::Email.server_settings = {
#   :address => "smtp.aa.powerset.com",
#   :port => 25,
#   :domain => "powerset.com"
# }
# 
# God::Contacts::Twitter.settings = {
#   # this is for my 'mojombo2' twitter test account
#   # feel free to use it for testing your conditions
#   :username => 'mojombo@gmail.com',
#   :password  => 'gok9we3ot1av2e'
# }

# God::Contacts::Campfire.defaults do |d|
#   d.subdomain = 'github'
#   d.token = 'f890cb46e983068e421975cc12fb76c6ff3f4f4f'
#   d.room = 'Notices'
#   d.ssl = true
# end

# God.contact(:email) do |c|
#   c.name = 'tom'
#   c.email = 'tom@mojombo.com'
#   c.group = 'developers'
# end
# 
# God.contact(:email) do |c|
#   c.name = 'vanpelt'
#   c.email = 'vanpelt@example.com'
#   c.group = 'developers'
# end
# 
# God.contact(:email) do |c|
#   c.name = 'kevin'
#   c.email = 'kevin@example.com'
#   c.group = 'platform'
# end
# 
# God.contact(:twitter) do |c|
#   c.name = 'tom2'
#   c.group = 'developers'
# end
# 
# God.contact(:prowl) do |c|
#   c.name = 'tom3'
#   c.apikey = 'd31c1f31f7af0f69e263c2f12167263127eab608'
#   c.group = 'developers'
# end

God.contact(:campfire) do |c|
  c.name = 'tom4'
  c.subdomain = 'github'
  c.token = 'f890cb46e983068e421975cc12fb76c6ff3f4f4f'
  c.room = 'Notices'
  c.ssl = true
end

God.watch do |w|
  w.name = "contact"
  w.interval = 5.seconds
  w.start = "ruby " + File.join(File.dirname(__FILE__), *%w[simple_server.rb])
  w.log = "/Users/tom/contact.log"

  # determine the state on startup
  w.transition(:init, { true => :up, false => :start }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end

    # failsafe
    on.condition(:tries) do |c|
      c.times = 2
      c.transition = :start
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_exits) do |c|
      c.notify = {:contacts => ['tom4'], :priority => 1, :category => 'product'}
    end
  end

  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 20.seconds
      c.transition = :unmonitored
      c.retry_in = 10.seconds
      c.retry_times = 2
      c.retry_within = 5.minutes
    end
  end
end