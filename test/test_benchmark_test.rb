require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/../lib/test_benchmark'

class TestBenchmarkTest < ActiveSupport::TestCase
  context "register_start" do
    should "record file method, timestamp and type" do
      test_benchmark = TestBenchmark.new
      test_benchmark.register_start(stub(:class => "TestClass", :method_name => "test_method"))
      assert test_benchmark.register.has_key?("TestClass")
      assert test_benchmark.register["TestClass"].has_key?("test_method")
      assert test_benchmark.register["TestClass"]["test_method"].start_time > 2.seconds.ago
    end
    
    should "not overwrite value entry per file for multiple tests" do
      test_benchmark = TestBenchmark.new
      test_benchmark.register_start(stub(:class => "TestClass", :method_name => "test_method_1"))
      test_benchmark.register_start(stub(:class => "TestClass", :method_name => "test_method_2"))

      assert test_benchmark.register["TestClass"].has_key?("test_method_1")
      assert test_benchmark.register["TestClass"].has_key?("test_method_2")
    end
  end
  
  context "register_end" do
    should "record end timestamp" do
      test = stub(:class => "TestClass", :method_name => "test_method")
      test_benchmark = TestBenchmark.new
      test_benchmark.register_start test
      test_benchmark.register_end test
      assert test_benchmark.register["TestClass"]["test_method"].end_time > 2.seconds.ago
    end
  end
  
  context "TestBenchmarkDuration" do
    context "duration" do
      should "equal the difference between end and start time" do
        test_benchmark = TestBenchmark.new
        test_benchmark.register_start(stub(:class => "TestClass", :method_name => "test_method"))
        test_benchmark.register_end(stub(:class => "TestClass", :method_name => "test_method"))
        datapoint = test_benchmark.register["TestClass"]["test_method"]
        assert_equal (datapoint.instance_variable_get(:@end_time) - datapoint.instance_variable_get(:@start_time)), datapoint.duration
      end
    end
  end
  
  context "duration" do
    should "equal 0 when there are no methods for a test class" do
      test_benchmark = TestBenchmark.new
      assert_equal 0, test_benchmark.duration("TestClass")
    end

    should "return time taken for entire test file" do
      test_benchmark = TestBenchmark.new
      test_benchmark.register_start(stub(:class => "TestClass", :method_name => "test_method_1"))
      test_benchmark.register_end(stub(:class => "TestClass", :method_name => "test_method_1"))
      test_benchmark.register_start(stub(:class => "TestClass", :method_name => "test_method_2"))
      test_benchmark.register_end(stub(:class => "TestClass", :method_name => "test_method_2"))
      datapoint_1 = test_benchmark.register["TestClass"]["test_method_1"]
      datapoint_2 = test_benchmark.register["TestClass"]["test_method_2"]
      assert_equal (datapoint_1.duration + datapoint_2.duration), test_benchmark.duration("TestClass")
    end
  end

  context "max_duration" do
    should "return longest time taken for entire test file" do
      test_benchmark = TestBenchmark.new
      test_benchmark.register_start(stub(:class => "TestClass", :method_name => "test_method_1"))
      test_benchmark.register_end(stub(:class => "TestClass", :method_name => "test_method_1"))
      test_benchmark.register_start(stub(:class => "TestClass", :method_name => "test_method_2"))
      sleep(0.1)
      test_benchmark.register_end(stub(:class => "TestClass", :method_name => "test_method_2"))
      datapoint_1 = test_benchmark.register["TestClass"]["test_method_1"]
      datapoint_2 = test_benchmark.register["TestClass"]["test_method_2"]
      assert_equal datapoint_2.duration, test_benchmark.max_duration("TestClass")
    end

    should "return 0 is test file has no entries" do
      assert_equal 0, TestBenchmark.new.max_duration("TestClass")
    end
  end
  
  context "average_duration" do
    should "return average time taken for entire test file" do
      test_benchmark = TestBenchmark.new
      test_benchmark.register_start(stub(:class => "TestClass", :method_name => "test_method_1"))
      test_benchmark.register_end(stub(:class => "TestClass", :method_name => "test_method_1"))
      test_benchmark.register_start(stub(:class => "TestClass", :method_name => "test_method_2"))
      test_benchmark.register_end(stub(:class => "TestClass", :method_name => "test_method_2"))
      datapoint_1 = test_benchmark.register["TestClass"]["test_method_1"]
      datapoint_2 = test_benchmark.register["TestClass"]["test_method_2"]
      assert_equal (datapoint_1.duration + datapoint_2.duration) / 2, test_benchmark.average_duration("TestClass")
    end

    should "return 0 if there are no methods for that test class" do
      test_benchmark = TestBenchmark.new
      assert_equal 0, test_benchmark.average_duration("TestClass")
    end
  end

  context "total_duration" do
    should "return time taken for entire suite" do
      test_benchmark = TestBenchmark.new
      test_benchmark.register_start(stub(:class => "TestClass1", :method_name => "test_method_1"))
      test_benchmark.register_end(stub(:class => "TestClass1", :method_name => "test_method_1"))
      test_benchmark.register_start(stub(:class => "TestClass2", :method_name => "test_method_2"))
      test_benchmark.register_end(stub(:class => "TestClass2", :method_name => "test_method_2"))
      assert_equal (test_benchmark.duration("TestClass1") + test_benchmark.duration("TestClass2")),
                    test_benchmark.total_duration
        
    end
    
    should "return 0 for empty suite" do
      test_benchmark = TestBenchmark.new
      assert_equal 0,test_benchmark.total_duration
    end
  end
  
  context "total_average_duration" do
    should "return average time taken for entire suite" do
      test_benchmark = TestBenchmark.new
      test_benchmark.register_start(stub(:class => "TestClass1", :method_name => "test_method_1"))
      test_benchmark.register_end(stub(:class => "TestClass1", :method_name => "test_method_1"))
      test_benchmark.register_start(stub(:class => "TestClass2", :method_name => "test_method_2"))
      test_benchmark.register_end(stub(:class => "TestClass2", :method_name => "test_method_2"))
      assert_equal (test_benchmark.duration("TestClass1") + test_benchmark.duration("TestClass2")) / 2,
                   test_benchmark.total_average_duration
    end

    should "return 0 for an empty suite" do
      test_benchmark = TestBenchmark.new
      assert_equal 0,test_benchmark.total_average_duration
    end
  end

  context "results?" do
    should "return true if register is nonempty" do
      test_benchmark = TestBenchmark.new
      test_benchmark.register_start(stub(:class => "TestClass1", :method_name => "test_method_1"))
      test_benchmark.register_end(stub(:class => "TestClass1", :method_name => "test_method_1"))
      assert test_benchmark.results?
    end

    should "return false if register is empty" do
      assert !TestBenchmark.new.results?
    end
  end

end
