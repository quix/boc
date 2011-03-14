require_relative 'main'
require_relative '../devel/levitate'
Levitate.doc_to_test("README.rdoc",
                     "Synopsis",
                     "Binding.of_caller shim for Ruby-1.8 code")
