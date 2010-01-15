require 'erb'

class TestBenchmarkHtmlFormatter
  
  BASE_DIRECTORY = (ENV['CC_BUILD_ARTIFACTS'] || (RAILS_ROOT + '/tmp')) + "/test_benchmarks"
  
  def self.dump(test_benchmark)
    return unless test_benchmark.results?
    top_level_text = ERB.new(File.readlines(File.dirname(__FILE__) + '/templates/top_level.html.erb').join(''))
    sorted_register = test_benchmark.register.sort_by {|test_class, methods| test_benchmark.max_duration test_class }.reverse
    unless File.directory? BASE_DIRECTORY
      FileUtils.mkdir BASE_DIRECTORY
    end
    File.open BASE_DIRECTORY + "/index.html", "w" do |file|
      file.write top_level_text.result(binding)
    end
    all_text = ERB.new(File.readlines(File.dirname(__FILE__) + '/templates/all.html.erb').join(''))
    flat_register = test_benchmark.register.to_a.inject([]) do |reg, group|
      test_class = group[0]
      group[1].each do |test_method, datapoint|
        reg << [test_class, test_method, datapoint.duration]
      end
      reg
    end
    sorted_flat_register = flat_register.sort_by { |line| line[2] }.reverse
    File.open BASE_DIRECTORY + "/all.html", "w" do |file|
      file.write all_text.result(binding)
    end
    test_file_text = ERB.new(File.readlines(File.dirname(__FILE__) + '/templates/test_file.html.erb').join(''))
    test_benchmark.register.each do |test_class, test_methods|
      sorted_test_methods = test_methods.sort_by do |method, datapoint| 
                                                        datapoint.duration
                                                      end.reverse
      File.open BASE_DIRECTORY + "/#{test_class}.html", "w" do |file|
        file.write test_file_text.result(binding)
      end
    end
  end
  
end