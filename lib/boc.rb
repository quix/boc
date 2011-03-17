require 'boc/boc'

module Boc
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

  #
  # <code>Boc.value</code> was called outside of an
  # <code>enable</code>d method.
  #
  class NotEnabledError < StandardError
  end

  #
  # The method given to <code>Boc.enable</code> appears to have been
  # already enabled.
  #
  class AlreadyEnabledError < StandardError
  end

  class << self
    #
    # Returns the binding of the caller. May only be used within an
    # <code>enable</code>d method.
    #
    def value
      if stack.empty?
        raise NotEnabledError, "Boc.value called outside of an enabled method"
      end
      stack.last
    end

    [:enable, :enable_basic_object].each do |def_method|
      define_method def_method do |klass, method_name|
        MODULE_EVAL.bind(klass).call do
          visibility = Boc.visibility klass, method_name

          impl = "#{method_name}__impl"
          Boc.check_enabled klass, method_name, impl

          Boc.no_warn { alias_method impl, method_name }
          Boc.send "#{def_method}_ext", klass, method_name
          
          send visibility, method_name
          public impl  # needs to work with rb_funcall_passing_block
        end
      end
    end

    def stack  #:nodoc:
      Thread.current[:_boc_stack] ||= []
    end

    #
    # squelch alias warnings
    #
    def no_warn  #:nodoc:
      prev = $VERBOSE
      $VERBOSE = nil
      begin
        yield
      ensure
        $VERBOSE = prev
      end
    end
    
    def visibility(klass, method_name)  #:nodoc:
      if klass.public_instance_methods.include?(method_name)
        :public
      elsif klass.protected_instance_methods.include?(method_name)
        :protected
      else
        :private
      end
    end

    def check_enabled(klass, method_name, impl)  #:nodoc:
      if klass.method_defined?(impl) or klass.private_method_defined?(impl)
        raise AlreadyEnabledError,
        "Boc.enable: refusing to overwrite `#{impl}' -- " <<
          "method `#{method_name}' appears to be already enabled"
      end
    end
  end

  MODULE_EVAL = Module.instance_method(:module_eval)  #:nodoc:
end
