class Numeric
  def seconds
    self
  end
  
  alias :second :seconds
  
  def minutes
    self * 60
  end
  
  alias :minute :minutes
  
  def hours
    self * 3600
  end
  
  alias :hour :hours
  
  def days
    self * 86400
  end
  
  alias :day :days
  
  def kilobytes
    self
  end
  
  alias :kilobyte :kilobytes
  
  def megabytes
    self * 1024
  end
  
  alias :megabyte :megabytes
  
  def gigabytes
    self * (1024 ** 2)
  end
  
  alias :gigabyte :gigabytes
  
  def percent
    self
  end
end