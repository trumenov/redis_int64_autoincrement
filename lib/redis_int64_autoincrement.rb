class RedisInt64Autoincrement

  # Why 50 seconds? Easy to debug and more than enouth for sync time delta shift.
  # You can use 10 or 5 seconds - and all must working normal too.
  # 50seconds was chosen by me without any explanation. Just took this value, i do not know why.
  REDIS_KEY_TTL_SECONDS = 50

  MAX_BUFFER_BITS_CNT = 63 # Do not use all 64 bits - in this case signed Int64 can be less than result uid
  TIMESTAMP_BITS_CNT = 34.freeze # 34bits for 150+ years more than enougth
  TIMESTAMP_MICROSECONDS_BITS_CNT = 20.freeze # 0..999_999 - require 20bits
  INCREMENTED_ID_BITS_CNT = 7.freeze  # 7bits for 0..127 INCREMENTED_UINT8_ID
  SERVER_ID_BITS_CNT = 2.freeze
  # So in result: 34 + 20 + 7 + 2 = 63bits(MAX_BUFFER_BITS_CNT).

  TIMESTAMP_SECONDS_SHIFT_LEFT_CNT = (TIMESTAMP_MICROSECONDS_BITS_CNT + INCREMENTED_ID_BITS_CNT + SERVER_ID_BITS_CNT).freeze # 29 bits
  TIMESTAMP_MICROSECONDS_SHIFT_LEFT_CNT = (INCREMENTED_ID_BITS_CNT + SERVER_ID_BITS_CNT).freeze # 9 bits
  INCREMENTED_ID_MAX_VAL    = ((1 << INCREMENTED_ID_BITS_CNT) - 1).freeze # 1111111b=127
  UINT63_MAX_VAL = 9223372036854775808 # 2^63 = 9223372036854775808
  LIB_FIRST_VAL  = 914476352027817480 # First id was generated 23.12.2023 at ~17:30 (Kiev +2:00)

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
    def generate(redis, namespace = 'default', options = {})
      server_id = options[:server_id] || 0
      time_redis = options[:time_redis] || redis
      raise("Wrong server_id[#{server_id}]. Allow only 0..3 server_id") unless server_id.between?(0, 3)
      time_arr = time_redis.time
      raise("Wrong time type[#{time_arr.inspect}]") unless time_arr.count.eql?(2)
      unix_seconds = time_arr.first.to_i
      first_part = unix_seconds << TIMESTAMP_SECONDS_SHIFT_LEFT_CNT

      microseconds = time_arr[1].to_i
      raise("Wrong microseconds [#{microseconds}]") unless microseconds.between?(0, 999_999)
      second_part = microseconds << TIMESTAMP_MICROSECONDS_SHIFT_LEFT_CNT

      key = "ai64:#{namespace}:#{unix_seconds}:#{microseconds}"
      incremented_val = redis.incrby(key, 1)
      redis.expire(key, REDIS_KEY_TTL_SECONDS)
      raise("Wrong incremented_val [#{incremented_val}]") unless incremented_val.between?(0, INCREMENTED_ID_MAX_VAL)
      third_part = incremented_val << SERVER_ID_BITS_CNT
      result = ((first_part | second_part) | third_part) | server_id
      raise("Wrong result[#{result}]") unless result.between?(LIB_FIRST_VAL, UINT63_MAX_VAL)
      result
    end
  end
end
