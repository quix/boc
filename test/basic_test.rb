require_relative 'main'

class BasicTest < BocTest
  MEMO = {}

  def setup
    MEMO.clear
  end

  class A
    def f(y, z)
      MEMO[:x] = eval("x", Boc.value)
      MEMO[:y] = y
      MEMO[:z] = z
      66
    end
    
    def g
      x = 33
      f(44, 55)
    end
  end

  def test_basic
    assert_raises Boc::NotEnabledError do
      Boc.value
    end

    Boc.enable A, :f

    assert_nil MEMO[:x]
    assert_nil MEMO[:y]
    assert_nil MEMO[:z]

    assert_equal 66, A.new.g

    assert_equal 33, MEMO[:x]
    assert_equal 44, MEMO[:y]
    assert_equal 55, MEMO[:z]

    assert_raises Boc::NotEnabledError do
      Boc.value
    end
  end

  class B
    def foo(*args, &block)
      MEMO[:args] = args
      MEMO[:block] = block
      eval("u", Boc.value) ;
    end
    
    def bar
      u = 66
      foo(77, 88) { |s| s + "zzz" }
    end
  end

  def test_explicit_block
    Boc.enable B, :foo

    assert_nil MEMO[:args]
    assert_nil MEMO[:block]

    assert_equal 66, B.new.bar
    assert_equal [77, 88], MEMO[:args]
    assert_equal "zoozzz", MEMO[:block].call("zoo")
  end

  class C
    def foo(*args)
      MEMO[:args] = args
      MEMO[:yield_result] = yield "moo"
      eval("u", Boc.value) ;
    end
    
    def bar
      u = 66
      foo(77, 88) { |s| s + "zzz" }
    end
  end

  def test_implicit_block
    Boc.enable C, :foo

    assert_nil MEMO[:args]
    assert_nil MEMO[:yield_result]

    assert_equal 66, C.new.bar
    assert_equal [77, 88], MEMO[:args]
    assert_equal "moozzz", MEMO[:yield_result]
  end

  module R
    def self.factorial_of_x
      x = eval("x", Boc.value) -
        if caller.grep(/#{__method__}/).size == (RUBY_ENGINE == "jruby" ? 0 : 1)
          0
        else
          1
        end
      
      if x == 0
        1
      else
        x*factorial_of_x
      end
    end
  end

  def test_recursive
    Boc.enable R.singleton_class, :factorial_of_x

    x = 5
    assert_equal 120, R.factorial_of_x
    x = 4
    assert_equal 24, R.factorial_of_x
    x = 1
    assert_equal 1, R.factorial_of_x
    x = 0
    assert_equal 1, R.factorial_of_x
  end

  def test_basic_object
    begin
      BasicObject.module_eval do
        def zoofoo
          ::Kernel.eval("z", ::Boc.value)
        end
      end

      Boc.enable_basic_object BasicObject, :zoofoo
      z = 77
      assert_equal 77, BasicObject.new.zoofoo
    ensure
      BasicObject.module_eval do
        remove_method :zoofoo
      end
    end
  end

  class D
    public
    def f ; end
    
    protected
    def g ; end

    private
    def h ; end
  end

  def test_visibility
    Boc.enable D, :f
    Boc.enable D, :g
    Boc.enable D, :h

    assert D.public_instance_methods.include?(:f)
    assert D.protected_instance_methods.include?(:g)
    assert D.private_instance_methods.include?(:h)

    D.new.f
    D.new.instance_eval { g }
    D.new.instance_eval { h }
  end

  class K
    def f(bind)
      eval("self", bind)
    end

    def self.g
      self.new.f(binding)
    end
  end

  def test_self_control
    Boc.enable K, :f
    assert_equal K, K.g
  end

  class L
    def f
      eval("self", Boc.value)
    end

    def self.g
      self.new.f
    end
  end

  def test_self
    Boc.enable L, :f
    assert_equal L, L.g
  end

  class K
    def k
    end
  end

  def test_double_enable
    Boc.enable K, :k
    error = assert_raises Boc::AlreadyEnabledError do
      Boc.enable K, :k
    end
    assert_match(/method `k'.*already/, error.message)
  end
end
