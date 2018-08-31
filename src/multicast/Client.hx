package multicast;

import multicast.impl.Connection;
import haxe.io.Bytes;

class Client
{
  var connection:Connection;
  var read_buf:Bytes;

  var uid = '${ Math.random() }-${ Math.random() }-${ Math.random() }';

  public function new(ip:String="233.255.255.250",
                      port:Int=29114,
                      buffer_size:Int=4096)
  {
    connection = new Connection(ip, port);
    read_buf = Bytes.alloc(buffer_size);
  }

  public function close():Void
  {
    if (connection==null) return;
    connection.close();
    connection = null;
  }

  public function send_message(msg:Dynamic):Void
  {
    if (connection==null) throw 'Error, connection closed';
    var payload = {
      from:uid,
      msg:msg
    }
    var bytes = serialize(payload);
    if (bytes.length>read_buf.length) {
      trace('Message size (${ bytes.length }) exceeds buffer (${ read_buf.length }), dropped.');
      return;
    }
    connection.write(bytes);
  }

  public function get_messages():Array<Dynamic>
  {
    if (connection==null) throw 'Error, connection closed';
    var msgs = [];
    var result = connection.read(read_buf);
    while (result.bytes_read>0) {
      var payload = unserialize(read_buf);
      if (payload.from!=uid) msgs.push(payload.msg);
      result = connection.read(read_buf);
    }
    return msgs;
  }

  private inline function serialize(obj:Dynamic):Bytes
  {
    // Could also use, e.g. hxbit
    var str = haxe.Serializer.run(obj);
    return Bytes.ofString(str);
  }

  private inline function unserialize(b:Bytes):Dynamic
  {
    // Could also use, e.g. hxbit
    return haxe.Unserializer.run(b.toString());
  }

}
