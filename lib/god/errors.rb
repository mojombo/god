module God
  
  class AbstractMethodNotOverriddenError < StandardError
  end
  
  class NoSuchWatchError < StandardError
  end
  
  class NoSuchConditionError < StandardError
  end
  
  class NoSuchBehaviorError < StandardError
  end
  
  class InvalidCommandError < StandardError
  end
  
end