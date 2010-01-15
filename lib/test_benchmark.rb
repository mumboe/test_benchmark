require File.expand_path(File.dirname(__FILE__) + '/test_benchmark_html_formatter')

class TestBenchmark
  attr_accessor :register, :start_time

  def initialize
    @register = {}
    @start_time = Time.now
  end
  
  def results?
    @register.any?
  end
  
  def max_duration(test_class)
    return 0 unless @register[test_class]
    @register[test_class].max { |a,b| a.last.duration <=> b.last.duration }.last.duration
  end
  
  def total_duration
    @register.inject 0 do |sum, test_class|
      sum + duration(test_class.first)
    end
  end
  
  def duration(test_class)
    return 0 unless @register[test_class] 
    @register[test_class].inject 0 do |sum, method|
      sum + method.last.duration
    end
  end
  
  def total_average_duration
    return 0 if total_duration.zero?
    total_method_count = @register.inject 0 do |sum, test_class|
      sum + test_class.last.size
    end
    total_duration / total_method_count
  end
  
  def average_duration(test_class)
    return 0 unless @register[test_class]
    duration(test_class) / @register[test_class].size
  end
    
  def register_start(test)
    @register[test.class.to_s] ||= {}
    @register[test.class.to_s][test.method_name] = TestBenchmarkDatapoint.new(Time.now)
  end
  
  def register_end(test)
    @register[test.class.to_s][test.method_name].end_time = Time.now
  end

  class TestBenchmarkDatapoint
    attr_accessor :start_time, :end_time
    
    def initialize(start_time)
      @start_time = start_time
    end
    
    def duration
      end_time - start_time
    end
  end
  
end
