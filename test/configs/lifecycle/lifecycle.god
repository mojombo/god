God::Contacts::Twitter.settings = {
  # this is for my 'mojombo2' twitter test account
  # feel free to use it for testing your conditions
  :username => 'mojombo@gmail.com',
  :password  => 'gok9we3ot1av2e'
}

God.contact(:twitter) do |c|
  c.name      = 'tom2'
  c.group     = 'developers'
end

God.watch do |w|
  w.name = "lifecycle"
  w.interval = 5.seconds
  w.start = "/dev/null"

  # lifecycle
  w.lifecycle do |on|
    on.condition(:always) do |c|
      c.what = true
      c.notify = "tom2"
    end
  end
end
