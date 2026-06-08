Pod::Spec.new do |s|
  s.name             = 'qrdniflut'
  s.version          = '1.0.3'
  s.summary          = 'Plugin para lectura y validación de códigos QR generados por la app MiDNI'
  s.description      = 'Plugin para lectura y validación de códigos QR generados por la app MiDNI'
  s.homepage         = 'https://github.com/diegocidm4/qrdniflutter.git'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Diego Cid Merion' => 'info@cqesolutions.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  # AÑADE ESTA LÍNEA PARA EL SDK NATIVO
  s.dependency 'iQRDNI', '~> 1.0.6'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end