
require 'boc.so'

module Boc
  class << self
    #
    # enable_basic_object is provided so that live_ast may replace
    # instance_eval. It may have no other legitimate use.
    #
    [:enable, :enable_basic_object].each do |def_method|
      define_method def_method do |klass, method_name|
        #
        # module_eval is saved so that live_ast may replace it.
        # Boc does not touch module_eval.
        #
        MODULE_EVAL.bind(klass).call do
          visibility =
            if public_instance_methods.include?(method_name)
              :public
            elsif protected_instance_methods.include?(method_name)
              :protected
            else
              :private
            end

          impl = "#{method_name}__impl"
          alias_method impl, method_name
          Boc.send "#{def_method}_ext", klass, method_name
          
          send visibility, method_name
          public impl  # needs to work with rb_funcall_passing_block
        end
      end
    end

    #
    # Returns the binding of the caller. May only be used within an
    # <code>enable</code>d method.
    #
    def value
      raise NotEnabledError if stack.empty?
      stack.last
    end

    def stack  #:nodoc:
      Thread.current[:_boc_stack] ||= []
    end
  end

  #
  # Boc.value was called outside of an <code>enable</code>d method.
  #
  class NotEnabledError < StandardError
    def message  #:nodoc:
      "Boc.value was called outside of an enabled method"
    end
  end

  #
  # module_eval is saved so that live_ast may replace it.
  # Boc does not touch module_eval.
  #
  MODULE_EVAL = Module.instance_method(:module_eval)  #:nodoc:

  #
  # :singleton-method: enable
  # :call-seq: enable(klass, method_name)
  #
  # Enable <code>Boc.value</code> for the given instance method.
  #
  #   class A
  #     def f
  #       p eval("x", Boc.value)
  #     end
  #     
  #     def self.g
  #       p eval("x", Boc.value)
  #     end
  #   end
  #
  #   Boc.enable A, :f
  #   Boc.enable A.singleton_class, :g
  #
  #   x = 33
  #   A.new.f  # => 33
  #   A.g  # => 33
  #
end
