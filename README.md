# QueueManager

Queue manager for Rails application. Based on Redis (Sorted Set).

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

Add the name of class worker in `config/initializers/queue_manager.rb`:

```ruby
  # Used sidekiq worker. Invokes method perform_async on this class
  config.worker = 'SidekiqWorker' # Default: nil
```

Start queue manager daemon:

    $ rake queue_manager:start

Add task to the queue:

```ruby
score = QueueManager::Task.add(7)
```

score - weight of task, is used to remove.

After 5 seconds, will be launched `SidekiqWorker.perform_async(7)`.

Remove task from the queue:

```ruby
QueueManager::Task.remove(7, score)
```

Stop queue manager daemon:

    $ rake queue_manager:stop


## Contributing

1. Fork it ( https://github.com/[my-github-username]/queue_manager/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
