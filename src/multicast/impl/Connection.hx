package multicast.impl;

import haxe.io.Bytes;
import haxe.io.Error;

#if cpp
  import multicast.impl.Bind_HXCPP as BindHelper;
#else
  #error "Multicast error: Unsupported platform! HXCPP only."
#end

class Connection
{
  public var ip(default,null):String;
  public var port(default,null):Int;
  public var is_bound(default,null) = false;
  public var err_cnt(default,null) = 0;

  var rx_buffer:Bytes;
  var udp:sys.net.UdpSocket;
  var addr:sys.net.Address;

// 225.225.0.1:38745

  public function new(ip:String="233.255.255.250",
                      port:Int=29114)
  {
    this.ip = ip;
    this.port = port;

    udp = new sys.net.UdpSocket();
    udp.setBlocking(false);

    addr = new sys.net.Address();
    addr.host = new sys.net.Host(ip).ip;
    addr.port = port;

    rx_buffer = Bytes.alloc(1024);

    try_bind();
  }

  public function close():Void
  {
    if (udp==null) return;
    udp.close();
    udp = null;
  }

  public function write(b:haxe.io.Bytes):Bool
  {
    if (udp==null) { err_cnt++; return false; }
    if (!is_bound) try_bind();
    if (!is_bound) return false;
    try {
      udp.sendTo(b,0,b.length, addr);
      return true;
    } catch (e:haxe.io.Error) {
      switch e {
        case Custom("EOF"):
          trace('Eof -- is the socket closed?');
          err_cnt++;
          return false;
        default:
          trace('Multicast write error: $e');
          err_cnt++;
          return false;
      }
    }
  }

  var from = new sys.net.Address();
  var read_result = new ReadResult();
  public function read(buffer:Bytes):ReadResult
  {
    // Reset return object
    @:privateAccess read_result.bytes_read = 0;
    @:privateAccess read_result.from_host = 0;

    if (udp==null) { err_cnt++; return read_result; }
    if (!is_bound) try_bind();

    try {
      @:privateAccess read_result.bytes_read = udp.readFrom(buffer,0,buffer.length,from);
      @:privateAccess read_result.from_host = from.host;
    } catch (e:haxe.io.Error) {
      switch e {
        case Blocked:
          // Nothing to read, ignore
        case Custom("EOF"):
          trace('Eof -- is the socket closed? Auto-reopen it?');
          err_cnt++;
        default:
          trace('Multicast read error: $e');
          err_cnt++;
      }
    } catch (e:haxe.io.Eof) {
      trace('Eof -- is the socket closed?');
      err_cnt++;
    }

    return read_result;
  }

  function try_bind()
  {
    if (is_bound) return;
    if (udp==null) { err_cnt++; return; }
    try {
      BindHelper.bind_multicast(udp, addr.host, addr.port);
      is_bound = true;
    } catch (e:Dynamic) {
      err_cnt++;
    }
  }
}

class ReadResult {
  public var bytes_read(default,null):Int = 0;
  public var from_host(default,null):Int = 0;
  public function new() { }
}
