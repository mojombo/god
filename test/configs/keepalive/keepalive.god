God.watch do |w|
  w.name = 'keepalive'
  w.start = File.join(GOD_ROOT, *%w[test configs keepalive keepalive.rb])
  w.log = File.join(GOD_ROOT, *%w[test configs keepalive keepalive.log])

  w.keepalive(:interval => 5.seconds,
              :memory_max => 10.megabytes,
              :cpu_max => 30.percent)
end
