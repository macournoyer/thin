require 'test_helper'

class SystemTest < Test::Unit::TestCase
  def test_processor_count
    assert_not_equal 0, Thin::System.processor_count
  end
  
  if Thin::System.java? || Thin::System.win?
    def test_should_not_support_fork
      assert ! Thin::System.supports_fork?
    end
  else
    def test_should_support_fork
      assert Thin::System.supports_fork?
    end
  end
end