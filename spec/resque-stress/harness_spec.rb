require 'spec_helper'

describe Resque::Stress::Harness do
  let(:harness) {Resque::Stress::Harness.new}
  describe "#validate!" do
    it "should raise error if name is nil" do
      harness.name = nil
      expect {harness.validate!}.to raise_error
    end

    it "should raise error if name is empty" do
      harness.name = ''
      expect {harness.validate!}.to raise_error
    end
  end

  context "aggregate ops" do
    let(:queue1) {Resque::Stress::QueueDef.new}
    let(:queue2) {Resque::Stress::QueueDef.new}
    let(:job1) {Resque::Stress::JobDef.new} 
    let(:job2) {Resque::Stress::JobDef.new} 
    let(:job3) {Resque::Stress::JobDef.new} 

    before do
      queue1.name = 'queue1'
      queue1.jobs << job1
      job1.queue = queue1
      queue1.jobs << job3
      job3.queue = queue1

      queue2.name = 'queue2'
      queue2.jobs << job2
      job2.queue = queue2

      job1.weight = 1
      job2.weight = 3
      job3.weight = 2

      harness.queues << queue1
      queue1.parent = harness
      harness.queues << queue2
      queue2.parent = harness
    end

    describe "#all_jobs" do
      it "should contain jobs from all queues" do
        result = Set.new(harness.all_jobs)
        result.should == Set.new([job1, job2, job3])
      end

      it "should have jobs sorted according to weight" do
        harness.all_jobs.should == [job2, job3, job1]
      end
    end

    describe "#total_weight" do
      it "should evaluate to the sum of all job weights" do
        expected = job1.weight + job2.weight + job3.weight
        harness.total_weight.should == expected
      end
    end

    describe "#job_for_roll" do
      it "should correctly pick job defs according to weighting" do
        harness.pick_job_def(0.1).should == job2
        harness.pick_job_def(0.2).should == job2
        harness.pick_job_def(0.3).should == job2
        harness.pick_job_def(0.4).should == job2
        harness.pick_job_def(0.5).should == job2
        harness.pick_job_def(0.6).should == job3
        harness.pick_job_def(0.7).should == job3
        harness.pick_job_def(0.8).should == job3
        harness.pick_job_def(0.9).should == job1
      end

      it "should pick most likely job for any arg < 0" do
        harness.pick_job_def(-1).should == job2
      end

      it "should pick least likely job for any arg >= 1" do
        harness.pick_job_def(1.0).should == job1
      end
    end
  end
end
