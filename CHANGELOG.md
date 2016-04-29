## 1.2.4
* [#3](https://github.com/NullVoxPopuli/action_cable_client/pull/3) Support Ruby 2.2.2 (@NullVoxPopuli)

## 1.2.3
* The ping message received from the action cable server changed from being identity: _ping to type: ping
* Fixed an issue where subscribing sometimes didn't work.

## 1.2.0
* Made the handling of received messages not all happen in one method. This allows for easier overriding of what is yielded, in case someone wants to also yield the URL for example.

## 1.1.0
* Made message queuing optional, off by default. This allows for near-instant message sending

## 1.0
* Initial Work
