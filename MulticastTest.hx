package;

import haxe.io.Bytes;
import haxe.io.Error;

class MulticastTest
{
  var tx_buffer:Bytes;
  var rx_buffer:Bytes;
  var udp:sys.net.UdpSocket;
  var addr:sys.net.Address;
  var uid = Math.floor( Math.random()*0x7fffff )+'-'+Math.floor( Math.random()*0x7fffff )+'-'+Math.floor( Math.random()*0x7fffff );

// 225.225.0.1:38745

  public function new()
  {
    var ip:String = "233.255.255.250";
    var port = 29114;

    udp = new sys.net.UdpSocket();
    addr = new sys.net.Address();
    udp.setBlocking(false);
    addr.host = new sys.net.Host(ip).ip; //0x7F000001; // 0xE9FFFFFF; // 233.255.255.255
    trace(addr.host);
    addr.port = port;

    MulticastHelper.bind_multicast(udp, new sys.net.Host(ip).ip, port);

    tx_buffer = Bytes.alloc(1024);
    rx_buffer = Bytes.alloc(1024);

    trace('Starting ping timer...');
    var t = new haxe.Timer(2500);
    t.run = ping;
    ping();

    var tr = new haxe.Timer(500);
    tr.run = function() {
      var d = read();
      if (d!=null) trace('RECEIVED: $d');
    }

    // Testing for closed error handling:
    // var tc = new haxe.Timer(5000);
    // tc.run = function() {
    //   udp.close();
    //   tc.stop();
    // }
  }

  private var _ping_msg:Bytes;
  private function ping()
  {
    if (_ping_msg==null) _ping_msg = serialize({ type:"ping", from:uid });
    write_bytes(_ping_msg);
  }

  private function serialize(obj:{}):Bytes
  {
    var str = haxe.Serializer.run(obj);
    return Bytes.ofString(str);
  }

  private function write_bytes(b:Bytes)
  {
    try {
      udp.sendTo(b,0,b.length, addr);
      trace('Sent ${ b.length } bytes (from me, $uid)');
    } catch (e:haxe.io.Error) {
      switch e {
        case Custom("EOF"):
          trace('Eof -- is the socket closed?');
        default:
          throw 'Multicast write error: $e';
      }
    }
  }

  private function read():Dynamic
  {
    try {
      var a = new sys.net.Address();
      var bytes_read:Int = udp.readFrom(rx_buffer,0,rx_buffer.length,a);
      var msg = haxe.Unserializer.run(rx_buffer.toString());
      if (msg!=null && Reflect.field(msg, "from")==uid) {
        // I'll ignore messages from myself
        return null;
      }
      return msg;
    } catch (e:haxe.io.Error) {
      switch e {
        case Blocked: // Nothing to read, ignore
        case Custom("EOF"):
          trace('Eof -- is the socket closed?');
        default:
          throw 'Multicast read error: $e';
      }
    } catch (e:haxe.io.Eof) {
      trace('Eof -- is the socket closed?');
    }
    return null;
  }

  public static function main() new MulticastTest();
}


// Combining some random code bits from:
//  - https://github.com/andyli/hxudp/blob/master/project/api.cpp
//  - https://github.com/HaxeFoundation/hxcpp/blob/master/src/hx/libs/std/Socket.cpp

// Importantly (I think), the "struct SocketWrapper" needs to match hxcpp's

@:headerCode('

#if !defined(HX_WINRT) && !defined(EPPC)
#include <hx/OS.h>

#include <string.h>


#ifdef NEKO_WINDOWS

#ifdef __GNUC__
   // Mingw / gcc on windows
   #define _WIN32_WINNT 0x0501
   #include <winsock2.h>
   #   include <Ws2tcpip.h>
#else
   // Windows...
   #include <winsock2.h>
   #include <In6addr.h>
   #include <Ws2tcpip.h>
#endif


#define DYNAMIC_INET_FUNCS 1
typedef WINSOCK_API_LINKAGE  INT (WSAAPI *inet_pton_func)( INT Family, PCSTR pszAddrString, PVOID pAddrBuf);
typedef WINSOCK_API_LINKAGE  PCSTR (WSAAPI *inet_ntop_func)(INT  Family, PVOID pAddr, PSTR pStringBuf, size_t StringBufSize);

#   define FDSIZE(n)   (sizeof(u_int) + (n) * sizeof(SOCKET))
#   define SHUT_WR      SD_SEND
#   define SHUT_RD      SD_RECEIVE
#   define SHUT_RDWR   SD_BOTH
   static bool init_done = false;
   static WSADATA init_data;
typedef int SocketLen;
#else
#   include <sys/types.h>
#   include <sys/socket.h>
#   include <sys/time.h>
#   include <netinet/in.h>
#  include <netinet/tcp.h>
#   include <arpa/inet.h>
#   include <unistd.h>
#   include <netdb.h>
#   include <fcntl.h>
#   include <errno.h>
#   include <stdio.h>
#   include <poll.h>
   typedef int SOCKET;
#   define closesocket close
#   define SOCKET_ERROR (-1)
#   define INVALID_SOCKET (-1)
typedef socklen_t SocketLen;
#endif

#if defined(NEKO_WINDOWS) || defined(NEKO_MAC)
#   define MSG_NOSIGNAL 0
#endif

#endif

')

  @:cppFileCode('

static int socketType = 0;

struct SocketWrapper : public hx::Object
{
   HX_IS_INSTANCE_OF enum { _hx_ClassId = hx::clsIdSocket };

   SOCKET socket;

   int __GetType() const { return socketType; }
};

SOCKET val_sock(Dynamic inValue)
{
   if (inValue.mPtr)
   {
      int type = inValue->__GetType();
      if (type==vtClass)
      {
         inValue = inValue->__Field( HX_CSTRING("__s"), hx::paccNever );
         if (inValue.mPtr==0)
            return 0;
         type = inValue->__GetType();
      }

      /// Hmmmm, UdpSocket???
      // if (type==socketType)
      //    return static_cast<SocketWrapper *>(inValue.mPtr)->socket;

      // Just trust it
      return static_cast<SocketWrapper *>(inValue.mPtr)->socket;
   }

   hx::Throw(HX_CSTRING("Invalid socket handle"));
   return 0;
}

void _hx_std_socket_bind_multicast( Dynamic o, int host, int port )
{
   SOCKET sock = val_sock(o);

   // First: bind to INADDR_ANY on our port
   int opt = 1;
   struct sockaddr_in addr;
   memset(&addr,0,sizeof(addr));
   addr.sin_family = AF_INET;
   addr.sin_port = htons(port);
   // addr.sin_addr.s_addr = INADDR_ANY;
   *(int*)&addr.sin_addr.s_addr = INADDR_ANY;
   #ifndef NEKO_WINDOWS
   setsockopt(sock,SOL_SOCKET,SO_REUSEADDR,(char*)&opt,sizeof(opt));
   setsockopt(sock,SOL_SOCKET,SO_REUSEPORT,(char*)&opt,sizeof(opt));
   #endif

   hx::EnterGCFreeZone();

   if( bind(sock,(struct sockaddr*)&addr,sizeof(addr)) == SOCKET_ERROR )
	 {
			hx::ExitGCFreeZone();
			hx::Throw(HX_CSTRING("Bind failed"));
	 }

		// join the multicast group
		struct ip_mreq mreq;
		mreq.imr_multiaddr.s_addr = host;
		mreq.imr_interface.s_addr = INADDR_ANY;

   // Second: setsockopt IP_ADD_MEMBERSHIP on our specific multicast address

   if( setsockopt(sock,IPPROTO_IP,IP_ADD_MEMBERSHIP,(char*)&mreq,sizeof(mreq)) == SOCKET_ERROR )
   {
      hx::ExitGCFreeZone();
      hx::Throw(HX_CSTRING("Bind failed"));
   }

   hx::ExitGCFreeZone();

}
')
class MulticastHelper {

  @:functionCode('
_hx_std_socket_bind_multicast(hx_socket, host, port);
')
  public static function bind_multicast(hx_socket:sys.net.Socket, host:Int, port:Int) {}
}
