# hx-multicast

Haxe UDP multicast library for hxcpp

[![Build Status](https://travis-ci.com/jcward/hx-multicast.svg?branch=master)](https://travis-ci.com/jcward/hx-multicast)

About
====

A simple UDP multicast library for Haxe / HXCPP, in simple .hx source, no extra ndlls or build steps.

UDP multicast allows message passing between many clients (devices or processes) on the same local area network (LAN), transmitting messages between them without any IP or host information. Messages sent from any client are delivered to all other clients.

Note that some routers, networks, or devices may not support UDP multicast. Also, with UDP, packets are not guaranteed to arrive, and are not guaranteed to arrive in the order they were sent. You should assume any packet could be lost.

Typical use cases are low-latency, low-bandwidth message passing. All message serializations must fit in the pre-allocated buffer size.

Example Usage
====

```
var mc = new multicast.Client();

// My uid: mc.uid
var members = [ mc.uid ];
var t = new haxe.Timer(2000);
t.run = function() {
  mc.emit({ type:"ping" });
  while (mc.has_next()) {
    var payload = mc.read();
    if (members.indexOf(payload.from_uid)<0) {
      members.push(payload.from_uid);
    }
  }
}
```
