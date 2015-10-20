require 'spec_helper'
require 'mock_redis'
require_relative '../../lib/queue_manager'

describe QueueManager::Task do
  let(:id)          { 'abcd' }
  let(:queue)       { QueueManager.config.queue }
  let(:mock_redis)  { MockRedis.new }
  let(:time)        { [1421157737, 875678] }
  let(:job)         { :TestJob }

  before do |example|
    allow(QueueManager::Task).to receive(:redis).and_return(mock_redis)
    allow(QueueManager::Task).to receive(:timestamp).and_return(time[0].to_i)

    allow_any_instance_of(QueueManager::Task).to receive(:redis).and_return(mock_redis)
    allow_any_instance_of(QueueManager::Task).to receive(:timestamp).and_return(time[0].to_i)

    unless example.metadata[:skip_stub_worker]
      test_job = double(:test_job)
      job_string = double(:job_string, constantize: test_job)
      allow(test_job).to receive(:perform_later)
      allow_any_instance_of(QueueManager::Task).to receive(:job).and_return(job_string)
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
  context '.add' do
    it 'raise an error if job is not present' do
      expect { QueueManager::Task.add(id, job: nil) }.to raise_error(ArgumentError, 'Job should be present')
    end

    it 'adds new task' do
      expect(mock_redis.zrange(queue, 0, -1)).to be_blank
      QueueManager::Task.add(id, job: job)
      expect(mock_redis.zrange(queue, 0, -1)).to match_array([id])
    end

    it 'adds already existing task' do
      expect(mock_redis.zrange(queue, 0, -1)).to be_blank
      3.times { QueueManager::Task.add(id, job: job) }
      expect(mock_redis.zrange(queue, 0, -1)).to match_array([id])
    end

    it 'adds task if already existing a marked task' do
      expect(mock_redis.zrange(queue, 0, -1)).to be_blank
      QueueManager::Task.add("*#{id}", job: job)
      expect(mock_redis.zrange(queue, 0, -1)).to match_array(["*#{id}"])
      QueueManager::Task.add(id, job: job)
      expect(mock_redis.zrange(queue, 0, -1)).to match_array(["*#{id}", id])
    end

    it 'returns instance of QueueManager::Task' do
      task = QueueManager::Task.add(id, job: job)
      expect(task).to be_instance_of QueueManager::Task
    end

     it 'sets options for the task', skip_stub_worker: true do
       task = QueueManager::Task.add(id, job: job)
       expect(task.job).to eq job.to_s
     end
  end

  context '.handling_queue' do
    it 'returns false if id and score is blank' do
      expect(mock_redis.zrange(queue, 0, -1)).to be_blank
      expect(QueueManager::Task.handling_queue).to eq false
    end

    it 'returns false if score great then timestamp' do
      QueueManager::Task.add(id, job: job)
      expect(mock_redis.zrange(queue, 0, -1)).to match_array([id])
      expect(QueueManager::Task.handling_queue).to eq false
    end

    it 'updates score for marked task' do
      expect(QueueManager.config).to receive(:delay).and_return(0)

      task = QueueManager::Task.add(id, job: job)
      mock_redis.zrem(queue, id)
      mock_redis.zadd(queue, task.score, "*#{id}")

      expect(mock_redis.zrange(queue, 0, -1, with_scores: true)).to match_array([["*#{id}", time[0].to_f]])
      QueueManager::Task.handling_queue
      new_score = time[0] + QueueManager.config.timeout
      expect(mock_redis.zrange(queue, 0, -1, with_scores: true)).to match_array([["*#{id}", new_score.to_f]])
    end

    it 'remove task and create marked task' do
      expect(QueueManager.config).to receive(:delay).and_return(0)
      task = QueueManager::Task.add(id, job: job)
      expect(mock_redis.zrange(queue, 0, -1, with_scores: true)).to match_array([[id, time[0].to_f]])
      QueueManager::Task.handling_queue
      new_score = time[0] + QueueManager.config.timeout
      expect(mock_redis.zrange(queue, 0, -1, with_scores: true)).to match_array([["*#{id}", new_score.to_f]])
    end

    it 'runs worker with additional arguments', skip_stub_worker: true do
      expect(QueueManager.config).to receive(:delay).and_return(0)
      task = QueueManager::Task.add(id, job: job, arg: 'arg1')
      allow(QueueManager::Task).to receive(:new).and_return(task)
      test_job = double(:test_job)
      job_string = double(:job_string, constantize: test_job)
      expect(test_job).to receive(:perform_later).with(task, id, arg: 'arg1')
      allow_any_instance_of(QueueManager::Task).to receive(:job).and_return(job_string)
      QueueManager::Task.handling_queue
    end
  end

  context '#remove' do
    it 'removes task' do
      expect(mock_redis.zrange(queue, 0, -1)).to be_blank

      task = QueueManager::Task.add(id, job: job)
      mock_redis.zrem(queue, id)
      mock_redis.zadd(queue, task.score, "*#{id}")

      expect(mock_redis.zrange(queue, 0, -1)).to match_array(["*#{id}"])
      task.remove
      expect(mock_redis.zrange(queue, 0, -1)).to be_blank
    end

    it 'not remove task', skip_stub_worker: true do
      expect(mock_redis.zrange(queue, 0, -1)).to be_blank

      task = QueueManager::Task.add(id, job: job)
      mock_redis.zrem(queue, id)
      mock_redis.zadd(queue, task.score, "*#{id}")

      expect(mock_redis.zrange(queue, 0, -1)).to match_array(["*#{id}"])
      task.update_score(task.score + 1)
      task.remove
      expect(mock_redis.zrange(queue, 0, -1)).to match_array(["*#{id}"])
    end

    it 'not remove not marked task' do
      expect(mock_redis.zrange(queue, 0, -1)).to be_blank
      task = QueueManager::Task.add(id, job: job)
      expect(mock_redis.zrange(queue, 0, -1)).to match_array([id])
      task.remove
      expect(mock_redis.zrange(queue, 0, -1)).to match_array([id])
    end

    it 'removes an arguments of the task', skip_stub_worker: true do
      task = QueueManager::Task.add(id, job: job)
      mock_redis.zrem(queue, id)
      mock_redis.zadd(queue, task.score, "*#{id}")

      expect(task.job).to eq job.to_s
      task.remove
      expect(task.job).to be_nil
    end

    it 'returns true' do
      task = QueueManager::Task.add(id, job: job)
      mock_redis.zrem(queue, id)
      mock_redis.zadd(queue, task.score, "*#{id}")
      expect(task.remove).to be_truthy
    end

    it 'returns false' do
      task = QueueManager::Task.add(id, job: job)
      expect(task.remove).to be_falsey
    end
  end

  context '#to_global_id' do
    it 'returns instance of GlobalID' do
      task = QueueManager::Task.add(id, job: job)
      expect(task.to_global_id).to be_instance_of GlobalID
    end
  end
end