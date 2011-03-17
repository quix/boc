require_relative 'main'
require_relative '../devel/levitate'

if RUBY_ENGINE == "ruby"
  Levitate.doc_to_test(
    "README.rdoc",
    "Synopsis",
    "<code>Binding.of_caller</code>")
end
