God::Contacts::Email.message_settings = {:from => 'support@gravatar.com'}

God::Contacts::Email.server_settings = {
  :address => "mail.authsmtp.com",
  :port => 2525,
  :domain => "gravatar.com",
  :authentication => :plain,
  :user_name => "xxx",
  :password => "yyy"
}

God.contact(:email) do |c|
  c.name = 'tom'
  c.email = 'tom@example.com'
  c.group = 'developers'
end

God.contact(:email) do |c|
  c.name = 'vanpelt'
  c.email = 'vanpelt@example.com'
  c.group = 'developers'
end

God.contact(:email) do |c|
  c.name = 'kevin'
  c.email = 'kevin@example.com'
  c.group = 'platform'
end

God.watch do |w|
  w.name = "contact"
  w.interval = 5.seconds
  w.start = "ruby " + File.join(File.dirname(__FILE__), *%w[simple_server.rb])
  
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
      c.notify = {:contacts => ['tom'], :priority => 1, :category => 'product'}
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