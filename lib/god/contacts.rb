module God::Contacts
  def self.const_missing(name)
    require "god/contacts/#{name}"
    ::CONTACT_LOAD_SUCCESS[name] = true
    const_get(name) if const_defined?(name, false)
  rescue LoadError
    ::CONTACT_LOAD_SUCCESS[name] = false
  end
end
