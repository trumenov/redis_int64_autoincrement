# encoding: UTF-8
# Author:: Andrew Chernuha chaky22222222@gmail.com
# License:: MIT and/or Creative Commons Attribution-ShareAlike

require 'test/unit'
require 'rubygems'
require 'redis_int64_autoincrement'
require "redis"

class TestRedisInt64Autoincrement < Test::Unit::TestCase

  def test_check_generated_placed_in_target_region
    redis = Redis.new(url: "redis://localhost:6379/0")
    left_part = Time.now.to_i << (RedisInt64Autoincrement::MAX_BUFFER_BITS_CNT - RedisInt64Autoincrement::TIMESTAMP_BITS_CNT)
    new_id = RedisInt64Autoincrement.generate(redis)
    right_part = (Time.now.to_i + 1) << (RedisInt64Autoincrement::MAX_BUFFER_BITS_CNT - RedisInt64Autoincrement::TIMESTAMP_BITS_CNT)
    assert new_id.between?(left_part, right_part)
  end
end
