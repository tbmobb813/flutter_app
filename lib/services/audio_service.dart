import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';


typedef _init_t = Void Function(Float, Int32);
typedef _start_t = Void Function(Pointer<Utf8>);
typedef _update_t = Void Function(Pointer<Utf8>);
typedef _stop_t = Void Function();


class AudioService {
static late final DynamicLibrary _lib;
static late final void Function(double, int) _init;
static late final void Function(Pointer<Utf8>) _start;
static late final void Function(Pointer<Utf8>) _update;
static late final void Function() _stop;


static Future<void> init(double sampleRate, int channels) async {
if (Platform.isAndroid) {
_lib = DynamicLibrary.open('libsoundcore.so');
} else if (Platform.isIOS) {
_lib = DynamicLibrary.process();
} else {
// desktop later
_lib = DynamicLibrary.open('libsoundcore.so');
}
_init = _lib.lookupFunction<_init_t, void Function(double, int)>('sc_init');
_start = _lib.lookupFunction<_start_t, void Function(Pointer<Utf8>)>('sc_start');
_update = _lib.lookupFunction<_update_t, void Function(Pointer<Utf8>)>('sc_update');
_stop = _lib.lookupFunction<_stop_t, void Function()>('sc_stop');


_init(sampleRate, channels);
}


static void start(String presetJson) {
final p = presetJson.toNativeUtf8();
_start(p);
calloc.free(p);
}


static void update(String updateJson) {
final p = updateJson.toNativeUtf8();
_update(p);
calloc.free(p);
}


static void stop() => _stop();
}