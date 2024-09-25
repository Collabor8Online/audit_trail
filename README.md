# AuditTrail

At [Collabor8Online](https://www.collabor8online.co.uk) a vital part of the functionality is keeping an audit trail.

(Also note that this gem was developed for use by us.  We're sharing it in case others find it useful, but depending upon demand, it will probably never be a true "community" project.  Finally note that currently it's licensed under the [LGPL](/LICENSE) which may make it unsuitable for some - contact us if you'd like to know about options).

This gem allows you to add a record of events that have happened within your application in an unobtrusive manner.  Events inherit their context from earlier events so you can prepare things in your controller and it carries through your models as you record subsequent events.

## To Do

- [ ] Results are not set by the block (used to work but no longer)
- [ ] Move .events into the service?

## Usage

Install the gem into your Rails application.  Then `include AuditTrail::User` into your `User` model and `include AuditTrail::Model` into any of your other models that you may need to report on.

For example, in Collabor8Online, we deal with Documents in Folders.  The end-user may wish to see a report on all events that have taken place regarding a particular document, or all events that have taken place in a given folder.  Both the `Document` and `Folder` classes are `AuditTrail::Model`s, meaning we can use `@document.linked_events.between(@first_date, @last_date)` or `@folder.linked_events.named("document.uploaded")`.

The `AuditTrail::Service` is an actor, so if you wish to use the return values, you must use `await`.  You can also use `wait_for` to check for results.  See the [documentation on actors](https://github.com/standard-procedure/plumbing/blob/main/docs/actors.md) for more information.

### Recording events

To record a single event, it's as simple as:

```ruby
AuditTrail.service.record "my_event"
```

Every event should have a name to describe it to the rest of your application.  I recommend name-spacing these - something like "collabor8.document.uploaded" - as these will then form the basis of your audit reports.

### Users

An event can optionally have a `User` recorded alongside it.  Internally this uses a polymorphic association, so it can be any ActiveRecord model you like.  However, including `AuditTrail::User` then means you can access events created by this user easily.

```ruby
class User < ApplicationRecord
  include AuditTrail::User
  validates :name, presence: true
end

@alice = User.create! name: "Alice"
await { AuditTrail.service.record "my_event", user: @alice }

@alice.events.first.name
# => "my_event"
```
### Event data

Each event can have data stored alongside it.  Any simple values (integers, strings etc) are serialised as YAML within the event and can be accessed through the `data` accessor.

```ruby
AuditTrail.service.record "my_event", hello: "world", number: 123

wait_for { @event = AuditTrail::Event.first }
@event.data[:hello]
# => "world"
@event.data[:number]
# => 123
```
### Linked models

As well as storing simple data, an event can be associated with arbitrary ActiveRecord models.  For example, in Collabor8, when assigning a WorkflowTask to someone, you also associate the task with a folder.  These are all stored alongside the "workflows.workflow_task.created" event.  Then, when someone wishes to report on everything that has happened to the task or folder the event is associated with them.

You can use the `AuditTrail::Model` module to access the events linked to your models.

```ruby
@folder = ...
@task = ...

await { AuditTrail.service.record "workflows.workflow_task.created", task: @task, folder: @folder }

@folder.linked_events.count
# => 1
@task.linked_events.first == @folder.linked_events.first
# => true
```

### Results

You can pass a `result` parameter through to the call to `#record`.  This is then stored as the `#result` of the event and can either be a simple type or an ActiveRecord model.

```ruby
@event = await { AuditTrail.service.record "something", result: 123 }

puts @event.result
# => 123

@alice = Person.find_by! name: "Alice"
@event = await { AuditTrail.service.record "something", result: @alice }

puts @event.result
# => @alice
```

### Stacking events

Events are hierarchical, forming a tree structure.  This is because one event in your application may result in multiple further events which may trigger even more events.

This can be handled simply by nesting your calls to `AuditTrail.service.record` and passing the context through to any subsequent events.

```ruby
AuditTrail.service.record "trigger" do |context|
  AuditTrail.service.record "child_event_1", context: context do |context|
    AuditTrail.service.record "grandchild_event_1", context: context
    AuditTrail.service.record "grandchild_event_2", context: context
  end
  AuditTrail.service.record "child_event_2", context: context
end

# produces a tree of events:
#
# trigger
# |-- child_event_1
# |   |-- grand_child_event_1
# |   |-- grand_child_event_2
# |-- child_event_2

wait_for { @trigger = AuditTrail::Event.find_by name: "trigger" }
puts @trigger.children.pluck(:name).join(", ")
# => child_event_1, child_event_2
@grand_child_event_1 = AuditTrail::Event.find_by name: "grand_child_event_1"
puts @grand_child_event_1.parent.name
# => child_event_1
```

If you pass a block to `AuditTrail.service.record` then the event that is created goes through a few statuses.

When `record` is called, a new `AuditTrail::Event` record is created, with a status of `in_progress` and with the user supplied.  Any data you pass in to the `record` method is stored with the event (either serialised or as a linked model).

Then the block is evaluated and any new events recorded in the context of your in progress event (see Inheritance below).

When the block finishes the original event is marked as `completed`.

However, if the block raises an exception, the exception class and message are stored in the event and the event is marked as `failed`.

### Inheritance

When you stack events by working inside a block, the child events inherit their user from the parent event, unless it is explicitly overridden.

This means you can create a top-level event in your controller, setting the user to the `current_user` from your session.  Then call a method in one of your models which itself records an event.  This model-triggered event is created in the context of the controller-triggered event, so automatically inherits your `current_user`, even though your model has no idea about what is going on at the controller level.

```ruby
class PostsController < ApplicationController
  def create
    AuditTrail.service.record "post_created", user: current_user do
      @post = Post.create! title: post_params[:title]
    end
  end
end

class Post < ApplicationRecord
  after_create :send_notification do
    AuditTrail.service.record "notification_sent", template: "new_post_notification" do |event|
      SubscriberMailer.with(post: self, sender: event.user).new_post_notification.deliver_later
    end
  end
end
# Both the "post_created" and "notification_sent" events will have their `user` set to `current_user`
```

You can also access the current context directly, although you do need to use `await` to ensure any asynchronous is handled correctly.  There's also a `current_user` method which returns the user from the current event.

```ruby
await { AuditTrail.service.current_context }
await { AuditTrail.service.current_user }
```

Finally, if you're using ActiveJob, you can pass the current context as a parameter to your job, then use `set_context` to ensure that any further events inherit this context.

```ruby
class ExportVideoJob < ApplicationJob
  queue_as :low_priority

  def perform event, video
    AuditTrail.service.in_context(event) do
      AuditTrail.service.record "video.exporting" do
        video.export
      end
    end
  end
end
```

The "video.exporting" event will be created in the context of the event passed in to the ExportVideoJob (including its user).

### Controlling the event status

Whilst calling `#record` will generate an event for you, with the option of passing in a block to handle "child" events, if you want more control over the life-cycle of the event, you can call `#start` and `#complete` (or `#fail`) yourself.

```ruby
begin
  @my_event = await { AuditTrail.service.start("my_event") }
  @result = do_some_complicated_work
  AuditTrail.service.complete @my_event, result: @result
rescue => ex
  AuditTrail.service.fail @my_event, ex
end
```

### Observing events

If you want to know when events happen, you can observe the audit trail.

Observation uses [plumbing](https://github.com/standard-procedure/plumbing) to publish a [pipe](https://github.com/standard-procedure/plumbing/blob/main/lib/plumbing/pipe.rb) that can have observers attached.  Be sure to check the [documentation](https://github.com/standard-procedure/plumbing/blob/main/docs/actors.md) about staying safe if you run Plumbing in threaded mode.

The notifications that you observe will have two parameters - the event's name, ending with ":started", ":completed" or ":failed".  And a `data` Hash that will have an :event containing `AuditTrail::Event`. itself.  This means you can use a [filter](https://github.com/standard-procedure/plumbing/blob/main/lib/plumbing/filter.rb) to observe only the events you are interested in, then use the event object itself to decide how you are going to react.

```ruby
# observe "document" events that have completed successfully
Plumbing::Filter.new source: AuditTrail.events do |event_name, data|
  event_name.start_with? "document" && event_name.end_with? ":completed"
end.add_observer do |event_name, data|
  do_something_with data[:event]
end

# log every failed event
Plumbing::Filter.new source: AuditTrail.events do |event_name, data|
  event_name.end_with? ":failed"
end.add_observer do |event_name, data|
  Rails.logger.error "Error - #{data[:event].exception_class}: #{data[:event].exception_message}"
end
```

## Installation
Add this line to your application's Gemfile:

```ruby
gem "c8o_audit_trail"
```

Then `AuditTrail.record` the events as needed (in your controllers, models and other functionality) and use `include AuditTrail::User` and `include AuditTrail::Model` to see which events are related to which models.
