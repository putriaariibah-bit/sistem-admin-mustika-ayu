{{flutter_js}}
{{flutter_build_config}}

// Pada sebagian ponsel Android, GPU merusak tembolok huruf CanvasKit
// (WebGL), sehingga beberapa huruf hilang atau berubah bentuk. Di Android
// aplikasi digambar dengan CPU; browser lain tetap memakai GPU.
const diAndroid = /Android/i.test(navigator.userAgent);

_flutter.loader.load({
  config: {
    canvasKitForceCpuOnly: diAndroid,
  },
});
