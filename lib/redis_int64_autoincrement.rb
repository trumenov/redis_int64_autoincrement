class RedisInt64Autoincrement
  MAX_BUFFER_BITS_CNT = 63 # Do not use all 64 bits - in this case signed Int64 can be less than result uid
  TIMESTAMP_BYTES_CNT = 34.freeze # 34bits for 150+ years more than enougth

  # Version number.
  module Version
    version = Gem::Specification.load(File.expand_path("../redis_int64_autoincrement.gemspec", File.dirname(__FILE__))).version.to_s.split(".").map { |i| i.to_i }
    MAJOR = version[1]
    MINOR = version[0]
    PATCH = version[1]
    STRING = "#{MAJOR}.#{MINOR}.#{PATCH}"
  end

  VERSION = Version::STRING

  class << self
    def generate(redis, options = {})
      0
    end
  end
end
