## 3.0.0

* [#27](https://github.com/NullVoxPopuli/action_cable_client/pull/27)
  * Implement reconnect
  * Fix issue with subscribing only working on initial connection
  * Additional Tests
  * Drop support for Ruby 2.2

## 2.0.2

* [#24](https://github.com/NullVoxPopuli/action_cable_client/pull/24) Fix bug where action cable client is too fast for the server and doesn't wait for the server's welcome message before initiating a channel subscription (@wpp)

## 2.0.1

**General**

* [#22](https://github.com/NullVoxPopuli/action_cable_client/pull/22) Removed ActiveSupport Dependency (@srabuini)

## 2.0

**General**

* [#18](https://github.com/NullVoxPopuli/action_cable_client/pull/18) Added the ability to reconnect (@NullVoxPopuli)
* [#19](https://github.com/NullVoxPopuli/action_cable_client/pull/19) Allow for additional params via the identifier (@mcary, @NullVoxPopuli)
* Support ruby-2.4.x
* [#20](https://github.com/NullVoxPopuli/action_cable_client/pull/20) Change underlying websocket gem to [websocket-eventmachine-client](https://github.com/imanel/websocket-eventmachine-client)
  * enables SSL
  * allows header usage on handshake

**Breaking**
* [#19](https://github.com/NullVoxPopuli/action_cable_client/pull/19) Removed queued_send in initializer - this allows for a action_cable_client to be simpler, and stay an true to real-time communication as possible -- also it wasn't being used.  (@NullVoxPopuli)
* Drop Support for ruby-2.2.x

## 1.3.4
* [#7](https://github.com/NullVoxPopuli/action_cable_client/pull/7) Avoid crashing on empty JSON data (@MikeAski)

## 1.3.2
* Getting disconnected from the server will now set the result of subscribed? to false (@NullVoxPopuli)

## 1.3.0
* subscribed now is a callback instead of a boolean (@NullVoxPopuli)
* subscribed? tells whether or not the client is subscribed to the channel (@NullVoxPopuli)
* added subscribed callback which signifies when the client can start sending messages on the channel (@NullVoxPopuli)

## 1.2.4
* [#3](https://github.com/NullVoxPopuli/action_cable_client/pull/3) Support Ruby 2.2.2 (@NullVoxPopuli)

## 1.2.3
* The ping message received from the action cable server changed from being identity: \_ping to type: ping (@NullVoxPopuli)
* Fixed an issue where subscribing sometimes didn't work. (@NullVoxPopuli)

## 1.2.0
* Made the handling of received messages not all happen in one method. This allows for easier overriding of what is yielded, in case someone wants to also yield the URL for example. (@NullVoxPopuli)

## 1.1.0
* Made message queuing optional, off by default. This allows for near-instant message sending (@NullVoxPopuli)

## 1.0
* Initial Work (@NullVoxPopuli)
