## 1.4 - Unreleased
* [18](https://github.com/NullVoxPopuli/action_cable_client/pull/18) Added the ability to reconnect (@NullVoxPopuli)

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
