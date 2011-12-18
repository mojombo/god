LOG_DIR = File.join(File.dirname(__FILE__), *%w[logs])

God.task do |t|
  t.name = 'task'
  t.valid_states = [:ok, :clean]
  t.initial_state = :ok
  t.interval = 5

  # t.clean = lambda do
  #   Dir[File.join(LOG_DIR, '*.log')].each do |f|
  #     File.delete(f)
  #   end
  # end

  t.clean = "rm #{File.join(LOG_DIR, '*.log')}"

  t.transition(:clean, :ok)

  t.transition(:ok, :clean) do |on|
    on.condition(:lambda) do |c|
      c.lambda = lambda do
        Dir[File.join(LOG_DIR, '*.log')].size > 1
      end
    end
  end
end
