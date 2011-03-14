#
# compatibility with the old-style Binding.of_caller from 1.8
# 

require 'boc'

class Binding
  def self.of_caller
    yield Boc.value
  end
end
