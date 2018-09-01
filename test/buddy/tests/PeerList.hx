package tests;

import buddy.*;
using buddy.Should;

class PeerList extends BuddySuite
{

  public function new() {
    describe("PeerList: 7 instances", {

      it("...and can be written to /tmp/MCPeers.hx...", function() {
        var exec_code = '
        class MCPeers {
          public static function main() {

            var mcs = [];
            var timers = [];

            var peers = [];
            function setup(mc:multicast.Client) {
              mcs.push(mc);
              var t = new haxe.Timer(500);
              t.run = function() {
                mc.emit({ type:"ping" });
                while (mc.has_next()) {
                  var payload = mc.read();
                  if (payload!=null && peers.indexOf(payload.from_uid)<0) {
                    peers.push(payload.from_uid);
                  }
                }
              }
            }

            // Setup 7 instances...
            for (i in 0...7) setup(new multicast.Client());

            // Simply wait a second...
            haxe.Timer.delay(function() {
              trace("There are "+peers.length+" peers");

              // tear down
              for (mc in mcs) mc.close();
              for (t in timers) t.stop();

            }, 1000);

          }
        }
        ';

        sys.io.File.saveContent('/tmp/MCPeers.hx', exec_code);
      });


      it("...and the haxe compiler must be on your path...", function() {
        var output = new sys.io.Process("which", ["haxe"]).stdout.readAll().toString();
        output.should.contain("/haxe");
      });

      var cwd = Sys.getCwd();
      trace(cwd);
      it("...and the code compile and execute as expected!", function() {
        var output = new sys.io.Process("haxe", ["--cwd", "/tmp", "-cp", cwd+"../../src", "-main", "MCPeers", "-cpp", "hxbout", "--next", "-cmd", "./hxbout/MCPeers"]).stdout.readAll().toString();
        output.should.contain('There are 7 peers');
      });


    });
  }
}
