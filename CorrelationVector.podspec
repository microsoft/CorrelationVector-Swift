Pod::Spec.new do |spec|

  spec.name         = "CorrelationVector"
  spec.version      = "1.0.0"
  spec.summary      = "Provides the Swift implementation of the CorrelationVector protocol for tracing and correlation of events through a distributed system."

  spec.description  = <<-DESC
  CorrelationVector library provides the Swift implementation of the CorrelationVector protocol for tracing and correlation of events through a distributed system. Correlation Vector (a.k.a. cV) is a format and protocol standard for tracing and correlation of events through a distributed system based on a light weight vector clock. The standard is widely used internally at Microsoft for first party applications and services and supported across multiple logging libraries and platforms (Services, Clients - Native, Managed, JS, iOS, Android etc). The standard powers a variety of different data processing needs ranging from distributed tracing & debugging to system and business intelligence, in various business organizations.
  DESC
  spec.homepage     = "https://github.com/microsoft/CorrelationVector"

  spec.license      = { :type => "MIT", :file => 'LICENSE' }
  spec.documentation_url = "https://github.com/microsoft/CorrelationVector"

  spec.author             = { "Microsoft" => "askcodex@microsoft.com" }
  
  spec.platform     = :ios, "9.0"
  spec.swift_version = '5.0'
  spec.source       = { :git => "https://github.com/microsoft/CorrelationVector-Swift.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/CorrelationVector/*.swift", "Sources/CorrelationVector/*.{c,h}"
  spec.preserve_path = 'README.md'

  spec.framework  = "Foundation"
  spec.requires_arc = true

end
