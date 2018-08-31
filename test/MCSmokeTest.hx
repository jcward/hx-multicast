package;

import haxe.io.Bytes;

class MCSmokeTest
{
  public static function main()
  {
    var mc = new multicast.Client();

    function ping()
    {
      var msg:Dynamic = { text:'Hello!' };
      if (Math.random()>0.8) {
        msg.bloat = "132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd";
        trace('Bloated');
      }
      mc.emit(msg);
    }

    trace('Starting ping timer...');
    var t = new haxe.Timer(2500);
    t.run = ping;
    ping();

    var t = new haxe.Timer(2500);
    t.run = function() {
      trace('Get msgs:');
      while (mc.has_next()) {
        var payload = mc.read();
        trace('RECEIVED: ${ payload.msg } from ${ payload.from_uid }');
      }
    }
  }

}

