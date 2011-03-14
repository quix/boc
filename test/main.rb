$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'minitest/unit'
require 'minitest/autorun' unless defined? Rake

require 'pp'
require 'boc'

class JLMiniTest < MiniTest::Unit::TestCase
  def self.test_methods
    default = super
    onlies = default.select { |m| m =~ %r!__only\Z! }
    if onlies.empty?
      default
    else
      puts "\nNOTE: running ONLY *__only tests for #{self}"
      onlies
    end
  end

  def delim(char)
    "\n" << (char*72) << "\n"
  end

  def mu_pp(obj)
    delim("_") <<
    obj.pretty_inspect.chomp <<
    delim("=")
  end

  def unfixable
    begin
      yield
      raise "claimed to be unfixable, but assertion succeeded"
    rescue MiniTest::Assertion
    end
  end

  def assert_nothing_raised
    yield
    assert_nil nil
  rescue => ex
    raise MiniTest::Assertion,
    exception_details(ex, "Expected nothing raised, but got:")
  end

  %w[
    empty equal in_delta in_epsilon includes instance_of
    kind_of match nil operator respond_to same
  ].each { |name|
    alias_method "assert_not_#{name}", "refute_#{name}"
  }
end

BocTest = JLMiniTest

