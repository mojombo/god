class Numeric
  # Public: Units of seconds.
  def seconds
    self
  end

  # Public: Units of seconds.
  alias :second :seconds

  # Public: Units of minutes (60 seconds).
  def minutes
    self * 60
  end

  # Public: Units of minutes (60 seconds).
  alias :minute :minutes

  # Public: Units of hours (3600 seconds).
  def hours
    self * 3600
  end

  # Public: Units of hours (3600 seconds).
  alias :hour :hours

  # Public: Units of days (86400 seconds).
  def days
    self * 86400
  end

  # Public: Units of days (86400 seconds).
  alias :day :days

  # Units of kilobytes.
  def kilobytes
    self
  end

  # Units of kilobytes.
  alias :kilobyte :kilobytes

  # Units of megabytes (1024 kilobytes).
  def megabytes
    self * 1024
  end

  # Units of megabytes (1024 kilobytes).
  alias :megabyte :megabytes

  # Units of gigabytes (1,048,576 kilobytes).
  def gigabytes
    self * (1024 ** 2)
  end

  # Units of gigabytes (1,048,576 kilobytes).
  alias :gigabyte :gigabytes

  # Units of percent. e.g. 50.percent.
  def percent
    self
  end
end
