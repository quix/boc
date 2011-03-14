require_relative 'main'

class ShimTest < BocTest
  def initialize(*args)
    super
    require 'boc/binding_of_caller'
  end

  class A
    def f
      Binding.of_caller do |bind|
        eval("x", bind) + 11
      end
    end
    
    def g
      x = 33
      f
    end
  end

  def test_old_style
    Boc.enable A, :f
    assert_equal 44, A.new.g
  end
end
