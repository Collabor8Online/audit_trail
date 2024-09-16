# AuditTrail

At [Collabor8Online](https://www.collabor8online.co.uk) a vital part of the functionality is keeping an audit trail.

(Also note that this gem was developed for use by us.  We're sharing it in case others find it useful, but depending upon demand, it will probably never be a true "community" project.  Finally note that currently it's licensed under the [LGPL](/LICENSE) which may make it unsuitable for some - contact us if you'd like to know about options).

This gem allows you to add a record of events that have happened within your application in an unobtrusive manner.  Events inherit their context from earlier events so you can prepare things in your controller and it carries through your models as you record subsequent events.

## Usage

Install the gem into your Rails application.  Then `include AuditTrail::User` into your `User` model and `include AuditTrail::Model` into any of your other models that you may need to report on.

For example, in Collabor8Online, we deal with Documents in Folders.  The end-user may wish to see a report on all events that have taken place regarding a particular document, or all events that have taken place in a given folder.  Both the `Document` and `Folder` classes are `AuditTrail::Model`s, meaning we can use `@document.linked_events.between(@first_date, @last_date)` or `@folder.linked_events.named("document.uploaded")`.

### Recording events

To record a single event, it's as simple as:

```ruby
AuditTrail.record "my_event"
```

Every event should have a name to describe it to the rest of your application.  I recommend namespacing these - something like "collabor8.document.uploaded" - as these will then form the basis of your audit reports.

### Users

An event can optionally have a `User` recorded alongside it.  Internally this uses a polymorphic association, so it can be any ActiveRecord model you like.  However, including `AuditTrail::User` then means you can access events created by this user easily.

```ruby
class User < ApplicationRecord
  include AuditTrail::User
  validates :name, presence: true
end

@alice = User.create! name: "Alice"
AuditTrail.record "my_event", user: @alice

@alice.events.first.name
# => "my_event"
```
### Event data

Each event can have data stored alongside it.  Any simple values (integers, strings etc) are serialised as YAML within the event and can be accessed through the `data` accessor.

```ruby
AuditTrail.record "my_event", hello: "world", number: 123

@event = AuditTrail::Event.first
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

AuditTrail.record "workflows.workflow_task.created", task: @task, folder: @folder

@folder.linked_events.count
# => 1
@task.linked_events.first == @folder.linked_events.first
# => true
```

### Stacking events

Events are hierarchical, forming a tree structure.  This is because one event in your application may result in multiple further events which may trigger even more events.

This can be handled simply by nesting your calls to `AuditTrail.record`

```ruby
AuditTrail.record "trigger" do
  AuditTrail.record "child_event_1" do
    AuditTrail.record "grandchild_event_1"
    AuditTrail.record "grandchild_event_2"
  end
  AuditTrail.record "child_event_2"
end

# produces a tree of events:
#
# trigger
# |-- child_event_1
# |   |-- grand_child_event_1
# |   |-- grand_child_event_2
# |-- child_event_2
#
```
If you pass a block to `AuditTrail.record` then the event that is created goes through a few statuses.

When `record` is called, a new `AuditTrail::Event` record is created, with a status of `in_progress` and with the user supplied.  Any data you pass in to the `record` method is stored with the event (either serialised or as a linked model).

Then the block is evaluated and any new events recorded are automatically attached as children to this parent event.

When the block finishes, the return value from the block is then stored as the `result` of the event, and the event is marked as `completed`.

However, if the block raises an exception, the exception class and message are stored in the event and the event is marked as `failed`.

### Inheritance

When you stack events each event inherits its context from its parent event.  In particular, this means that the user is automatically carried through to child events.

This means you can create a top-level event in your controller, setting the user to your `current_user`.  Then call a method in one of your models which itself records an event.  This model-triggered event is created in the context of the controller-triggered event, so automatically inherits your `current_user`, even though your model has no idea who is logged in.

```ruby
class PostsController < ApplicationController
  def create
    AuditTrail.record "post_created", user: current_user do
      @post = Post.create! title: post_params[:title]
    end
  end
end

class Post < ApplicationRecord
  after_create :send_notification do
    AuditTrail.record "notification_sent", template: "new_post_notification" do
      SubscriberMailer.with(post: self).new_post_notification.deliver_later
    end
  end
end

# Both the "post_created" and "notification_sent" events will have their `user` set to `current_user`
```

### Context

If you need to access the current activity, you can by using:

```ruby
AuditTrail.context_stack.current
```

The context is handled as a stack, so as events are completed, the stack is popped back to the previous level.

Additionally, the context stack is stored in a thread local variable - so if your Rails app uses multiple threads, each one's context is independent.  If you use a fiber-based server, like Falcon, then it should work independently as well as ruby treats thread local variables as fiber local (but I've not tested this).

If you're using ActiveJob, then your jobs will run in a separate process (or maybe in a separate thread).  Either way, the context will be lost by the time that the job is started.  However, as events are ActiveRecord models, you can pass the current context as parameter to your job, then pass it in to your `AuditTrail.record` call to attach any further events to your existing stack.

```ruby
class PostsController < ApplicationController
  def create
    AuditTrail.record "post_created", user: current_user do
      @post = Post.create! title: post_params[:title]
    end
  end
end

class Post < ApplicationRecord
  after_create :send_notification do
    AuditTrail.record "subscriber_notification_scheduled" do
      SendNewPostNotificationToSubscribersJob.perform_later self, context: AuditTrail.context_stack.current
    end
  end
end

class SendNewPostNotificationToSubscribersJob < ApplicationJob
  def perform post, context: nil
    Subscriber.find_each do |subscriber|
      AuditTrail.record "notification_sent", template: "new_post_notification", context: context do
        SubscriberMailer.with(post: self, recipient: subscriber).new_post_notification.deliver_later
      end
    end
  end
end
```

### Subscribing to events

If you want to know when events happen, you can observe to the audit trail.

Observation uses [plumbing](https://github.com/standard-procedure/plumbing) to publish a [pipe](https://github.com/standard-procedure/plumbing/blob/main/lib/plumbing/pipe.rb) that can have observers attached.

The notifications that you observe will have a `type` property that is the event's name, ending with ":started", ":completed" or ":failed".  The `data` property will be the `AuditTrail::Event`. itself.  This means you can use a [filter](https://github.com/standard-procedure/plumbing/blob/main/lib/plumbing/filter.rb) to observe only the events you are interested in, then use the event object itself to decide how you are going to react.

```ruby
# Filter out all events except "document" events that have completed successfully
@document_filter = Plumbing::Filter.new source: AuditTrail.events do |notification|
  notification.type.start_with? "document" && notification.type.end_with? ".completed"
end
@document_filter.add_observer do |notification|
  @document_filter.safely do
    do_something_with notification.data
  end
end
```

## Installation
Add this line to your application's Gemfile:

```ruby
gem "c8o_audit_trail"
```

Then `AuditTrail.record` the events as needed (in your controllers, models and other functionality) and use `include AuditTrail::User` and `include AuditTrail::Model` to see which events are related to which models.
