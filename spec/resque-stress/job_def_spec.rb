require 'spec_helper'
require 'benchmark'

describe Resque::Stress::JobDef do
  let(:job_def) {Resque::Stress::JobDef.new}
  before do
    job_def.queue = :my_queue
    job_def.class_name = :my_job
  end

  describe "#class_name" do
    it "should convert string to camelcase version" do
      job_def.class_name.should == "MyJob"
    end

    it "should fail fast if the passed arg would not be valid class name" do
      expect{ job_def.class_name=nil }.to raise_error
    end
  end

  describe "#runtime_min" do
    it "should default to 1" do
      job_def.runtime_min.should == 1
    end
  end

  describe "#runtime_max" do
    it "should default to 1" do
      job_def.runtime_max.should == 1
    end
  end

  describe "#weight" do
    it "should default to 1" do
      job_def.weight.should == 1
    end
  end

  describe "#error_rate" do
    it "should default to 0" do
      job_def.error_rate.should == 0
    end
  end

  describe "#validate!" do
    it "should raise exception if queue is not present" do
      job_def.queue = nil
      expect{job_def.validate!}.to raise_error
    end

    it "should raise exception if @class_name is not present" do
      job_def.instance_variable_set(:@class_name, nil)
      expect{job_def.validate!}.to raise_error
    end

    it "should raise exception if runtime_min is not <= runtime_max" do
      job_def.runtime_min = 2
      job_def.runtime_max = 1
      expect{job_def.validate!}.to raise_error
    end
  end

  describe "#to_job_class" do
    before {job_def.runtime_max = 2}
    let(:job_class) {job_def.to_job_class}

    it "should return a job class with a name matching the defs class_name" do
      job_class.should == MyJob
    end

    it "should return a job class with a @queue variable matching the defs queue" do
      job_class.instance_variable_get(:@queue).should == :my_queue
    end

    it "should return a job class with a @runtime_range var that is def.runtime_min..def.runtime_max" do
      job_class.instance_variable_get(:@runtime_range).should == (1..2)
    end

    it "should return a job class with an @error_rate var matching the defs error_rate" do
      job_class.instance_variable_get(:@error_rate).should == 0
    end

    it "should have a perform class method defined" do
      job_class.respond_to?(:perform).should == true
    end

    describe "#perform" do
      it "should take between runtime_min and runtime_max to perform" do
        job = job_class
        bm = Benchmark.measure {job.perform}
        (bm.real > job_def.runtime_min).should == true
        (bm.real < job_def.runtime_max).should == true
      end

      it "should raise errors according to the job defs error rate." do
        job_def.error_rate = 1.0
        expect{job_class.perform}.to raise_error
      end
    end
  end
end