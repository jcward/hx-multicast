# hx-multicast

Haxe UDP multicast library for hxcpp

[![Build Status](https://travis-ci.com/jcward/hx-multicast.svg?branch=master)](https://travis-ci.com/jcward/hx-multicast)

About
====

A simple UDP multicast library for Haxe / HXCPP, in simple .hx source, no extra ndlls or build steps.

Works with hxcpp 3.4.49 up to the current release 4.0.4.

UDP multicast allows message passing between many clients (devices or processes) on the same local area network (LAN), transmitting messages between them without any IP or host information. Messages sent from any client are delivered to all other clients.

Note that some routers, networks, or devices may not support UDP multicast. Also, with UDP, packets are not guaranteed to arrive, and are not guaranteed to arrive in the order they were sent. You should assume any packet could be lost.

Typical use cases are low-latency, low-bandwidth message passing. All message serializations must fit in the pre-allocated buffer size.

Example Usage
====

Install with `haxelib install multicast`, and add `-lib multicast` to your hxml. For OpenFL, add `<haxelib name="multicast" />` to your `project.xml` file.

Example Test.hx:
```haxe
class Test
{
  public static function main()
  {
    var mc = new multicast.Client();
    trace('I am: ${ mc.uid }');

    // My uid: mc.uid
    var peers = [ mc.uid ];

    // In a typical game setting, instead of a Timer, you might
    // send+check messages from your event loop.
    var t = new haxe.Timer(2000);
    t.run = function() {
      mc.emit({ type:"ping" });
      while (mc.has_next()) {
        var payload = mc.read();
        if (payload!=null && peers.indexOf(payload.from_uid)<0) {
          trace('Hello, ${ payload.from_uid } !');
          peers.push(payload.from_uid);
        }
      }
    }

  }
}

// ... some time later, cleanup
// t.stop();
// mc.close();
```

Running this test from two different terminals:

![image](https://user-images.githubusercontent.com/2192439/44942400-16c74a00-ad6d-11e8-84af-0429a6961cbc.png)
