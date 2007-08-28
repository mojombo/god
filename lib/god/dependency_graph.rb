module God
  class DependencyGraph
    attr_accessor :nodes
    
    def initialize
      self.nodes = {}
    end
    
    def add(a, b)
      node_a = self.nodes[a] || Node.new(a)
      node_b = self.nodes[b] || Node.new(b)
      
      node_a.add(node_b)
      
      self.nodes[a] ||= node_a
      self.nodes[b] ||= node_b
    end
  end
end

module God
  class DependencyGraph
    class Node
      attr_accessor :name
      attr_accessor :dependencies
      
      def initialize(name)
        self.name = name
        self.dependencies = []
      end
      
      def add(node)
        self.dependencies << node unless self.dependencies.include?(node)
      end
      
      def has_node?(node)
        (self == node) || self.dependencies.any { |x| x.has_node?(node) }
      end
    end
  end
end