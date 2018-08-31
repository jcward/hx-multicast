package;

import haxe.io.Bytes;

class MCSmokeTest
{
  public static var uid(default,null) = Math.floor( Math.random()*0x7fffff )+'-'+Math.floor( Math.random()*0x7fffff )+'-'+Math.floor( Math.random()*0x7fffff );

  public static function main()
  {
    var mc = new multicast.Client();

    function ping()
    {
      var msg:Dynamic = { text:'Hello from ${ uid }' };
      if (Math.random()>0.8) {
        msg.bloat = "132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd132ewrgw34trfd";
        trace('Bloated');
      }
      mc.send_message(msg);
    }

    trace('Starting ping timer...');
    var t = new haxe.Timer(2500);
    t.run = ping;
    ping();

    var t = new haxe.Timer(2500);
    t.run = function() {
      trace('Get msgs:');
      var msgs = mc.get_messages();
      for (m in msgs) trace('RECEIVED: $m');
    };
  }

}

