module God
  module CLI

    class Version
      def self.version
        require 'god'

        # print version
        puts "Version #{God.version}"
        exit
      end

      def self.version_extended
        puts "Version: #{God.version}"
        puts "Polls: enabled"
        puts "Events: " + God::EventHandler.event_system

        exit
      end
    end

  end
end
