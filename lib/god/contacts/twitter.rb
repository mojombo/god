# Send a notice to a Twitter account (http://twitter.com/).
#
# consumer_token  - The String OAuth consumer token (defaults to God's
#                   existing consumer token).
# consumer_secret - The String OAuth consumer secret (defaults to God's
#                   existing consumer secret).
# access_token    - The String OAuth access token.
# access_secret   - The String OAuth access secret.

CONTACT_DEPS[:twitter] = ['twitter']
CONTACT_DEPS[:twitter].each do |d|
  require d
end

module God
  module Contacts
    class Twitter < Contact
      class << self
        attr_accessor :consumer_token, :consumer_secret,
                      :access_token, :access_secret
      end

      self.consumer_token = 'gOhjax6s0L3mLeaTtBWPw'
      self.consumer_secret = 'yz4gpAVXJHKxvsGK85tEyzQJ7o2FEy27H1KEWL75jfA'

      def valid?
        valid = true
        valid &= complain("Attribute 'consumer_token' must be specified", self) unless arg(:consumer_token)
        valid &= complain("Attribute 'consumer_secret' must be specified", self) unless arg(:consumer_secret)
        valid &= complain("Attribute 'access_token' must be specified", self) unless arg(:access_token)
        valid &= complain("Attribute 'access_secret' must be specified", self) unless arg(:access_secret)
        valid
      end

      attr_accessor :consumer_token, :consumer_secret,
                    :access_token, :access_secret

      def notify(message, time, priority, category, host)
        oauth = ::Twitter::OAuth.new(arg(:consumer_token), arg(:consumer_secret))
        oauth.authorize_from_access(arg(:access_token), arg(:access_secret))

        ::Twitter::Base.new(oauth).update(message)

        self.info = "sent twitter update"
      rescue => e
        applog(nil, :info, "failed to send twitter update: #{e.message}")
        applog(nil, :debug, e.backtrace.join("\n"))
      end
    end
  end
end
