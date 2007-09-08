require 'execve'

my_env = ENV.to_hash.merge('HOME' => '/foo')
# my_env = ENV.to_hash

env = my_env.keys.inject([]) { |acc, k| acc << "#{k}=#{my_env[k]}"; acc }

execve(%Q{ruby -e "puts ENV['HOME']"}, env)
