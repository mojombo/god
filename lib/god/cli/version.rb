module God
  module CLI

    class Version
      def self.version
        require 'god'

        # print version
        puts "Version #{God::VERSION::STRING}"
        exit
      end

      def self.version_extended
        puts "Version: #{God::VERSION::STRING}"
        puts "Polls: enabled"
        puts "Events: " + God::EventHandler.event_system

        exit
      end
    end

  end
end