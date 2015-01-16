require 'spec_helper'
require 'mock_redis'
require_relative '../../lib/queue_manager'

describe QueueManager::Task do
  let(:id)          { 'abcd' }
  let(:queue)       { QueueManager.config.queue }
  let(:mock_redis)  { MockRedis.new }
  let(:time)        { [1421157737, 875678] }

  before :each do |example|
    unless example.metadata[:skip_stub_redis]
      allow(QueueManager::Task).to receive(:redis).and_return(mock_redis)
      allow(QueueManager::Task).to receive(:timestamp).and_return(time[0].to_i)
    end

    unless example.metadata[:skip_stub_worker]
      allow(QueueManager.config).to receive(:worker).and_return(nil)
    end
  end

  # Constants
  context '::MARKER' do
    it 'returns string' do
      expect(QueueManager::Task::MARKER).to eq '*'
    end
  end

  context '::MARKED_REGEXP' do
    it 'returns a regexp' do
      expect(QueueManager::Task::MARKED_REGEXP).to eq /^\*/
      expect(QueueManager::Task::MARKED_REGEXP).to be_instance_of Regexp
    end
  end

  # Public methods
  context :add do
    it 'adds new task' do
      expect(mock_redis.zrange(queue, 0, -1)).to be_blank
      QueueManager::Task.add(id)
      expect(mock_redis.zrange(queue, 0, -1)).to match_array([id])
    end

    it 'adds already existing task' do
      expect(mock_redis.zrange(queue, 0, -1)).to be_blank
      3.times { QueueManager::Task.add(id) }
      expect(mock_redis.zrange(queue, 0, -1)).to match_array([id])
    end

    it 'adds task if already existing a marked task' do
      expect(mock_redis.zrange(queue, 0, -1)).to be_blank
      QueueManager::Task.add("*#{id}")
      expect(mock_redis.zrange(queue, 0, -1)).to match_array(["*#{id}"])
      QueueManager::Task.add(id)
      expect(mock_redis.zrange(queue, 0, -1)).to match_array(["*#{id}", id])
    end

    it 'returns score of task' do
      score = QueueManager::Task.add(id)
      expect(score).to be_instance_of Fixnum
      expect(mock_redis.zscore(queue, id)).to eq score
    end
  end

  context :remove do
    it 'removes task' do
      expect(mock_redis.zrange(queue, 0, -1)).to be_blank
      score = QueueManager::Task.add("*#{id}")
      expect(mock_redis.zrange(queue, 0, -1)).to match_array(["*#{id}"])
      QueueManager::Task.remove(id, score)
      expect(mock_redis.zrange(queue, 0, -1)).to be_blank
    end

    it 'not remove task' do
      expect(mock_redis.zrange(queue, 0, -1)).to be_blank
      score = QueueManager::Task.add("*#{id}")
      expect(mock_redis.zrange(queue, 0, -1)).to match_array(["*#{id}"])
      QueueManager::Task.remove(id, score+1)
      expect(mock_redis.zrange(queue, 0, -1)).to match_array(["*#{id}"])
    end

    it 'not remove not marked task' do
      expect(mock_redis.zrange(queue, 0, -1)).to be_blank
      score = QueueManager::Task.add(id)
      expect(mock_redis.zrange(queue, 0, -1)).to match_array([id])
      QueueManager::Task.remove(id, score)
      expect(mock_redis.zrange(queue, 0, -1)).to match_array([id])
    end
  end

  context :handling_queue do
    it 'returns false if id and score is blank' do
      expect(mock_redis.zrange(queue, 0, -1)).to be_blank
      expect(QueueManager::Task.handling_queue).to eq false
    end

    it 'returns false if score great then timestamp' do
      QueueManager::Task.add(id)
      expect(mock_redis.zrange(queue, 0, -1)).to match_array([id])
      expect(QueueManager::Task.handling_queue).to eq false
    end

    it 'updates score for marked task' do
      expect(QueueManager.config).to receive(:delay).and_return(0)
      QueueManager::Task.add("*#{id}")
      expect(mock_redis.zrange(queue, 0, -1, with_scores: true)).to match_array([["*#{id}", time[0].to_f]])
      QueueManager::Task.handling_queue
      new_score = time[0] + QueueManager.config.timeout
      expect(mock_redis.zrange(queue, 0, -1, with_scores: true)).to match_array([["*#{id}", new_score.to_f]])
    end

    it 'remove task and create marked task' do
      expect(QueueManager.config).to receive(:delay).and_return(0)
      QueueManager::Task.add(id)
      expect(mock_redis.zrange(queue, 0, -1, with_scores: true)).to match_array([[id, time[0].to_f]])
      QueueManager::Task.handling_queue
      new_score = time[0] + QueueManager.config.timeout
      expect(mock_redis.zrange(queue, 0, -1, with_scores: true)).to match_array([["*#{id}", new_score.to_f]])
    end

    it 'runs worker', skip_stub_worker: true do
      worker_class = double(:worker_class)
      worker_string = double(:worker_string, constantize: worker_class)
      expect(worker_class).to receive(:perform_async).with(id)
      expect(QueueManager.config).to receive(:worker).twice.and_return(worker_string)
      expect(QueueManager.config).to receive(:delay).and_return(0)
      QueueManager::Task.add(id)
      QueueManager::Task.handling_queue
    end
  end

  # Private methods
  context :redis, skip_stub_redis: true do
    it 'returns an instance of Redis' do
      expect(QueueManager::Task.send(:redis)).to be_instance_of Redis
    end
  end

  context :timestamp, skip_stub_redis: true do
    it 'returns integer' do
      redis = double(:redis, time: time)
      expect(QueueManager::Task).to receive(:redis).and_return(redis)
      expect(QueueManager::Task.send(:timestamp)).to eq time[0].to_i
    end
  end

  context :transaction do
    it 'invokes methods watch and unwatch' do
      expect(mock_redis).to receive(:watch).with(QueueManager.config.queue)
      QueueManager::Task.send(:transaction) { 'test' }
    end
  end
end