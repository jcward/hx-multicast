package multicast;

import multicast.impl.Connection;
import haxe.io.Bytes;

typedef UIDType = Int;

class Client
{
  var connection:Connection;
  var read_buf:Bytes;

  public var uid(default,null):UIDType = Std.int(Math.random()*0x7FFFFFFF);

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

  public function emit(msg:Dynamic):Void
  {
    if (connection==null) throw 'Error, connection closed';
    var payload = new Payload(uid, msg);
    var bytes = serialize(payload);
    if (bytes.length>read_buf.length) {
      trace('Message size (${ bytes.length }) exceeds buffer (${ read_buf.length }), dropped.');
      return;
    }
    connection.write(bytes);
  }

  private var _next_payload:Payload = null;

  public function has_next():Bool
  {
    if (_next_payload==null) _next_payload = peek_next();
    return _next_payload!=null;
  }

  public function read():Payload
  {
    if (_next_payload!=null) {
      var rtn = _next_payload;
      _next_payload = null;
      return rtn;
    } else {
      return peek_next();
    }
  }

  private function peek_next():Payload
  {
    if (connection==null) throw 'Error, connection closed';
    var result = connection.read(read_buf);
    if (result.bytes_read==0) return null;
    var payload:Payload = try unserialize(read_buf) catch (e:Dynamic) null;
    if (payload!=null && payload.from_uid!=uid) return payload;
    return null;
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

class Payload
{
  public function new(from_uid:UIDType=null, msg:Dynamic=null) {
    this.from_uid = from_uid;
    this.msg = msg;
  }
  public var from_uid:UIDType;
  public var msg:Dynamic;
}
