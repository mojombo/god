require File.dirname(__FILE__) + '/helper'

class TestDependencyGraph < Test::Unit::TestCase
  def setup
    @dg = DependencyGraph.new
  end
  
  # new
  
  def test_new_should_accept_zero_arguments
    assert @dg.instance_of?(DependencyGraph)
  end
  
  # add
  
  def test_add_should_create_and_store_two_new_nodes
    @dg.add('foo', 'bar')
    assert_equal 2, @dg.nodes.size
    assert @dg.nodes['foo'].instance_of?(DependencyGraph::Node)
    assert @dg.nodes['bar'].instance_of?(DependencyGraph::Node)
  end
  
  def test_add_should_record_dependency
    @dg.add('foo', 'bar')
    assert_equal 1, @dg.nodes['foo'].dependencies.size
    assert_equal @dg.nodes['bar'], @dg.nodes['foo'].dependencies.first
  end
  
  def test_add_should_ignore_dups
    @dg.add('foo', 'bar')
    @dg.add('foo', 'bar')
    assert_equal 2, @dg.nodes.size    
    assert_equal 1, @dg.nodes['foo'].dependencies.size
  end
end


class TestDependencyGraphNode < Test::Unit::TestCase
  def setup
    @foo = DependencyGraph::Node.new('foo')
    @bar = DependencyGraph::Node.new('bar')
  end
  
  # new
  
  def test_new_should_accept_zero_arguments
    assert @foo.instance_of?(DependencyGraph::Node)
  end
  
  # add
  
  def test_add_should_store_node_as_dependency
    @foo.add(@bar)
    assert_equal 1, @foo.dependencies.size
  end
  
  # has_node?
  
  def test_has_node
    assert @foo.has_node?(@foo)
  end
end