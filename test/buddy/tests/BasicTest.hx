package tests;

import buddy.*;
using buddy.Should;

class BasicTest extends BuddySuite
{

  public function new() {
    describe("BasicTest: two instances", {

      var inst1;
      var inst2;
      it('should instantiate', {
        inst1 = new multicast.Client();
        inst2 = new multicast.Client();
      });

      it('and send messages', {
        inst1.emit({ foo:"bar1" });
        inst2.emit({ abc:123 });
      });

      it('and it should wait', {
          inst1.has_next();
          inst2.has_next();
      });    

      it('and read the expected messages', {
        var msg_in_1 = inst1.read();
        var msg_in_2 = inst2.read();
      
        msg_in_1.from_uid.should.be(inst2.uid);
        msg_in_2.from_uid.should.be(inst1.uid);
      
        msg_in_1.msg.abc.should.be(123);
        msg_in_2.msg.foo.should.be("bar1");
      });
      

    });
  }
}



/*
  public function new() {
    describe("BasicTest: two instances", {

      it("...and can be written to /tmp/StarWars.hx...", function() {
        var exec_code = '
        class MCTwoInstances {
          public static function main() {
            var inst1 = new multicast.Client();
            var inst2 = new multicast.Client();

            haxe.Timer.delay(function() {
              inst1.emit({ foo:"bar1" });
              inst2.emit({ abc:123 });
            }, 10);

            haxe.Timer.delay(function() {
              var msg_in_1 = inst1.read();
              var msg_in_2 = inst2.read();
              trace("correct1: "+(msg_in_2.msg.foo=="bar1"));
              trace("correct2: "+(msg_in_1.msg.abc==123));
            }, 250);

          }
        }
        ';

        sys.io.File.saveContent('/tmp/MCTwoInstances.hx', exec_code);
      });

      it("...and the haxe compiler must be on your path...", function() {
        var output = new sys.io.Process("which", ["haxe"]).stdout.readAll().toString();
        output.should.contain("/haxe");
      });

      var cwd = Sys.getCwd();
      trace(cwd);
      it("...and the code will be executed by the Haxe compiler!", function() {
        var output = new sys.io.Process("haxe", ["--cwd", "/tmp", "-cp", cwd+"../../src", "-main", "MCTwoInstances", "-cpp", "hxbout", "--next", "-cmd", "./hxbout/MCTwoInstances"]).stdout.readAll().toString();
        output.should.contain('correct1: true');
        output.should.contain('correct2: true');
      });


    });
  }

*/
