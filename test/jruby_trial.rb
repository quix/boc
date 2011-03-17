require_relative 'main'

class JrubyTest < BocTest
  require 'jruby'
  prop = "jruby.astInspector.enabled"
  puts("#{prop}: " + java.lang.System.get_properties[prop].inspect)

  class A
    def f
      eval("x", Boc.value)
    end
  end

  def test_explosion
    #p { }
    Boc.enable A, :f
    x = 33
    assert_equal 33, A.new.f
  end
end if RUBY_ENGINE == "jruby"
