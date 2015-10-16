# Queue Manager

Queue manager for your Rails application with support Active Job. Under the hood Redis and [sorted sets](http://redis.io/topics/data-types#sorted-sets). 

[![Gem Version](https://badge.fury.io/rb/queue_manager.svg)](http://badge.fury.io/rb/queue_manager)
[![Build Status](https://travis-ci.org/mgrachev/queue_manager.svg?branch=master)](https://travis-ci.org/mgrachev/queue_manager)
[![Coverage Status](https://coveralls.io/repos/mgrachev/queue_manager/badge.svg?branch=master&service=github)](https://coveralls.io/github/mgrachev/queue_manager?branch=master)
[![Code Climate](https://codeclimate.com/github/mgrachev/queue_manager/badges/gpa.svg)](https://codeclimate.com/github/mgrachev/queue_manager)
[![Dependency Status](https://gemnasium.com/mgrachev/queue_manager.svg)](https://gemnasium.com/mgrachev/queue_manager)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'queue_manager'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install queue_manager

Run installer:

    $ rails generate queue_manager:install

## Usage

Start the queue manager

    $ rake queue_manager:start

Create a new job

    $ rails generate job test


Rails creates a new class `TestJob` into `app/jobs/test_job.rb`.
Change it to work with the queue manager: 

```ruby
class TestJob < ActiveJob::Base
  queue_as :default

  def perform(task, id, **kwargs)
    # Do something later
    # ...
    task.done
  end
end
```

Method `perform` should take the following arguments:

* `task` - the task of the queue manager;
* `id` - the unique identifier of the task;
* `kwargs` - hash with additional arguments.

What can you do with a task:

* Remove it from the queue: `task.remove` or `task.done`
* Change the job of this task at the next start: `task.job = :OtherTestJob`
* Passing the additional argument for the next start: `task.options = { arg2: 'var2' }`

Add the task to the queue:

```ruby
task = QueueManager.add_task(7, job: :TestJob, arg1: 'var1')
```

Until such time as the task has not yet been taken in the process, you can change its parameters through the variable `task`.
Once the task has taken the work, control it can only `TestJob` and evenly until the task is again back in the lineup for the timeout.

After a certain period of time, the queue manager takes the task in processing and starts job

```ruby
TestJob.perform_later(task, 7, arg1: 'var1')
```

To stop the queue manager, run

    $ rake queue_manager:stop

## Contributing

1. Fork it ( https://github.com/[my-github-username]/queue_manager/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
