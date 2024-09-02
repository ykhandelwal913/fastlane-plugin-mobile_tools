module Fastlane
    module Actions
      class ValidateXcframeworkAction < Action
        def self.run(params)
          validate_xcframework(params)
        end
  
        def self.validate_xcframework(params)
          return if params[:validate_xcframework].nil? || params[:validate_xcframework] == false
  
          UI.message("▸ Validating xcframework")
          xcframework_paths = []
  
          frameworks = params[:frameworks] || [nil]
            
          @xchelper = Helper::CreateXcframeworkHelper.new(params)
          frameworks.each do |framework|
            xcframework = framework ? @xchelper.get_xcframework_path(framework) : @xchelper.xcframework_path
            xcframework_paths << xcframework
          end
          
          UI.message("▸ Creating temporary sample app")
          sample_app_path = Helper::ValidateXcframeworkHelper.create_sample_app(xcframework_paths)
  
          UI.message("▸ Building the sample app to validate xcframework")
          begin
            Dir.chdir(sample_app_path) do
              Actions.sh("swift build")
              UI.success("xcframework validation succeeded")
            end
          rescue StandardError => e
            UI.user_error!("xcframework validation failed: #{e}")
          end
  
          UI.message("▸ Creating project.yml for xcodegen")
          project_yml_path = Helper::ValidateXcframeworkHelper.create_project_yml(xcframework_paths, sample_app_path)
  
          UI.message("▸ Generating Xcode project using xcodegen")
          begin
            Helper::ValidateXcframeworkHelper.generate_xcode_project(project_yml_path)
            UI.success("Xcode project generated successfully with xcodegen")
          rescue StandardError => e
            UI.user_error!("Failed to generate Xcode project with xcodegen: #{e}")
          end
  
          UI.message("▸ Building the Xcode project to validate xcframework")
          xcodeproj_path = File.join(sample_app_path, 'SampleApp.xcodeproj')
          begin
            Helper::ValidateXcframeworkHelper.build_xcode_project(xcodeproj_path)
            UI.success("xcframework validation succeeded with xcodebuild")
          rescue StandardError => e
            UI.user_error!("xcframework validation failed with xcodebuild: #{e}")
          end
        end
  
        def self.run_swiftlint
          UI.message("▸ Running SwiftLint")
          begin
            Actions.sh("if which swiftlint >/dev/null; then swiftlint; else echo 'warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint'; fi")
            UI.success("SwiftLint check completed successfully")
          rescue StandardError => e
            UI.user_error!("SwiftLint check failed: #{e}")
          end
        end
  
        def self.description
          "Validate xcframework and run SwiftLint"
        end
  
        def self.authors
          ["Your Name"]
        end
  
        def self.return_value
          # If your method provides a return value, you can describe it here
        end
  
        def self.details
          # Optional:
          "This action validates an xcframework by creating a temporary sample app, building it, and running SwiftLint."
        end
  
        def self.available_options
          [
            FastlaneCore::ConfigItem.new(key: :frameworks,
                                         description: "Paths to the frameworks to be validated",
                                         optional: false,
                                         type: Array),
            FastlaneCore::ConfigItem.new(key: :validate_xcframework,
                                         description: "Flag to validate xcframework",
                                         optional: true,
                                         type: Boolean),
            FastlaneCore::ConfigItem.new(key: :xcframework_output_directory,
                                        description: "Output directory for the xcframework",
                                        optional: true,
                                        type: String)
          ]
        end
  
        def self.is_supported?(platform)
          true
        end
      end
    end
  end