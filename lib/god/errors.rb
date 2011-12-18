module God

  class AbstractMethodNotOverriddenError < StandardError
  end

  class NoSuchWatchError < StandardError
  end

  class NoSuchConditionError < StandardError
  end

  class NoSuchBehaviorError < StandardError
  end

  class NoSuchContactError < StandardError
  end

  class InvalidCommandError < StandardError
  end

  class EventRegistrationFailedError < StandardError
  end

end
