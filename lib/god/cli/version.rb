module God
  module CLI
    
    class Version
      def self.version
        require 'god'
    
        # print version
        puts "Version #{God::VERSION}"
        exit
      end
      
      def self.version_extended
        puts "Version: #{God::VERSION}"
        puts "Polls: enabled"
        puts "Events: " + God::EventHandler.event_system
    
        exit
      end
    end
    
  end
end