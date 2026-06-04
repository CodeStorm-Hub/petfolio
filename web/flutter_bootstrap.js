{{flutter_js}}
{{flutter_build_config}}

(function () {
  var isAppleWebKit =
    /iPad|iPhone|iPod/i.test(navigator.userAgent) ||
    (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);

  var loadOptions = {};
  if (!isAppleWebKit) {
    loadOptions.serviceWorkerSettings = {
      serviceWorkerVersion: {{flutter_service_worker_version}},
    };
  }

  _flutter.loader.load(loadOptions);
})();
