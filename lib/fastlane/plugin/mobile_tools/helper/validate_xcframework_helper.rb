module Fastlane
    module Helper
      class ValidateXcframeworkHelper
        def self.create_sample_app(framework_paths)
          tmpdir = Dir.mktmpdir
          sample_app_path = File.join(tmpdir, 'SampleApp')
          Dir.mkdir(sample_app_path)
          Dir.chdir(sample_app_path) do
            system("swift package init --type executable")
            tests_path = File.join(sample_app_path, 'Tests', 'SampleAppTests')
            FileUtils.mkdir_p(tests_path)
  
            # Copy frameworks to the temporary sample app folder
            framework_paths.each do |path|
              FileUtils.cp_r(path, sample_app_path)
            end
  
            package_swift_path = File.join(sample_app_path, 'Package.swift')
            # Extract names from framework paths and ensure paths are relative
            binary_targets = framework_paths.map do |path|
              name = File.basename(path, ".framework")
              relative_path = "./" + File.basename(path)
              ".binaryTarget(name: \"#{name}\", path: \"#{relative_path}\")"
            end.join(",\n        ")
  
            # Create dependencies for SampleApp target
            dependencies = framework_paths.map do |path|
              name = File.basename(path, ".framework")
              "\"#{name}\""
            end.join(", ")
  
            resources = framework_paths.map do |path|
              name = File.basename(path, ".framework")
              ".copy(\"./#{name}.framework\")"
            end.join(",\n                      ")
  
            # Add all framework names to the products target
            product_targets = framework_paths.map do |path|
              name = File.basename(path, ".framework")
              "\"#{name}\""
            end.join(", ")
  
            package_swift_content = <<-SWIFT
            // swift-tools-version:5.3
            import PackageDescription
  
            let package = Package(
                name: "SampleApp",
                platforms: [
                    .macOS(.v10_15),
                    .iOS(.v13)
                ],
                products: [
                    .executable(name: "SampleApp", targets: ["SampleApp", #{product_targets}]),
                ],
                dependencies: [
                    // Add dependencies here
                ],
                targets: [
                    #{binary_targets},
                    .target(
                        name: "SampleApp",
                        dependencies: [#{dependencies}],
                        path: "Sources",
                        resources: [
                            #{resources}
                        ]
                    ),
                    .testTarget(
                        name: "SampleAppTests",
                        dependencies: ["SampleApp"],
                        path: "Tests/SampleAppTests"
                    ),
                ]
            )
            SWIFT
  
            File.write(package_swift_path, package_swift_content.strip)
          end
          sample_app_path
        end
  
        def self.create_project_yml(framework_paths, sample_app_path)
          project_yml_content = {
            "name" => "SampleApp",
            "options" => {
              "bundleIdPrefix" => "com.intuit"
            },
            "targets" => {
              "SampleApp" => {
                "type" => "application",
                "platform" => "iOS",
                "deploymentTarget" => "13.0",
                "sources" => ["Sources"],
                "resources" => framework_paths.map { |path| "./#{File.basename(path)}" },
                "dependencies" => framework_paths.map { |path| { "framework" => "./#{File.basename(path)}", "embed" => true } },
                "settings" => {
                  "base" => {
                    "DEVELOPMENT_TEAM" => "F6DWWXWEX6",
                    "GENERATE_INFOPLIST_FILE" => "YES",
                    "CODE_SIGN_IDENTITY" => "iPhone Developer",
                    "LD_RUNPATH_SEARCH_PATHS" => ["$(inherited)", "@executable_path/Frameworks"],
                    "SDKROOT" => "iphoneos",
                    "TARGETED_DEVICE_FAMILY" => "1,2",
                    "VERSIONING_SYSTEM" => "apple-generic",
                    "CURRENT_PROJECT_VERSION" => "1",
                    "MARKETING_VERSION" => "1.0",
                    "CFBundleVersion" => "$(CURRENT_PROJECT_VERSION)",
                    "CFBundleShortVersionString" => "$(MARKETING_VERSION)"
                  },
                  "configs" => {
                    "debug" => {
                      "CODE_SIGN_STYLE" => "Manual",
                      "PROVISIONING_PROFILE_SPECIFIER" => "com.intuit.*.InHouse",
                      "CODE_SIGN_IDENTITY" => "iPhone Distribution: Intuit Inc.(Ent)"
                    },
                    "release" => {
                      "CODE_SIGN_STYLE" => "Manual",
                      "PROVISIONING_PROFILE_SPECIFIER" => "com.intuit.*.InHouse",
                      "CODE_SIGN_IDENTITY" => "iPhone Distribution: Intuit Inc.(Ent)"
                    }
                  }
                }
              }
            }
          }
  
          project_yml_path = File.join(sample_app_path, 'project.yml')
          File.write(project_yml_path, project_yml_content.to_yaml)
          project_yml_path
        end
  
        def self.generate_xcode_project(project_yml_path)
          Actions.sh("xcodegen generate --spec #{project_yml_path}")
        end
  
        def self.build_xcode_project(xcodeproj_path)
          Actions.sh("xcodebuild -project #{xcodeproj_path} -scheme SampleApp -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 14' build")
        end
      end
    end
  end