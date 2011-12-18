# God::Contacts::Campfire.defaults do |d|
#   d.subdomain = 'github'
#   d.token = '9fb768e421975cc1c6ff3f4f8306f890cb46e24f'
#   d.room = 'Notices'
#   d.ssl = true
# end
#
# God.contact(:campfire) do |c|
#   c.name = 'tom4'
# end

# God.contact(:email) do |c|
#   c.name = 'tom'
#   c.group = 'developers'
#   c.to_email = 'tom@lepton.local'
#   c.from_email = 'god@github.com'
#   c.from_name = 'God'
#   c.delivery_method = :sendmail
# end

# God.contact(:email) do |c|
#   c.name = 'tom'
#   c.group = 'developers'
#   c.to_email = 'tom@mojombo.com'
#   c.from_email = 'god@github.com'
#   c.from_name = 'God'
#   c.server_host = 'smtp.rs.github.com'
# end

# God.contact(:prowl) do |c|
#   c.name = 'tom3'
#   c.apikey = 'f0fc8e1f3121672686337a631527eac2f1b6031c'
#   c.group = 'developers'
# end

# God.contact(:twitter) do |c|
#   c.name = 'tom6'
#   c.consumer_token = 'gOhjax6s0L3mLeaTtBWPw'
#   c.consumer_secret = 'yz4gpAVXJHKxvsGK85tEyzQJ7o2FEy27H1KEWL75jfA'
#   c.access_token = '17376380-qS391nCrgaP4HKXAmZtM38gB56xUXMhx1NYbjT6mQ'
#   c.access_secret = 'uMwCDeU4OXlEBWFQBc3KwGyY8OdWCtAV0Jg5KVB0'
# end

# God.contact(:scout) do |c|
#   c.name = 'tom5'
#   c.client_key = '583a51b5-acbc-2421-a830-b6f3f8e4b04e'
#   c.plugin_id = '230641'
# end

# God.contact(:webhook) do |c|
#   c.name = 'tom'
#   c.url = "http://www.postbin.org/wk7guh"
# end

# God.contact(:jabber) do |c|
#   c.name = 'tom'
#   c.host = 'talk.google.com'
#   c.to_jid = 'mojombo@jabber.org'
#   c.from_jid = 'mojombo@gmail.com'
#   c.password = 'secret'
# end

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
