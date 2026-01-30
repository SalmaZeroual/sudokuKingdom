import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();
  
  IO.Socket? _socket;
  
  void connect() {
    if (_socket != null && _socket!.connected) return;
    
    _socket = IO.io(AppConstants.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });
    
    _socket!.onConnect((_) {
      print('Socket connected');
    });
    
    _socket!.onDisconnect((_) {
      print('Socket disconnected');
    });
    
    _socket!.onError((error) {
      print('Socket error: $error');
    });
  }
  
  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }
  
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }
  
  void off(String event) {
    _socket?.off(event);
  }
  
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}