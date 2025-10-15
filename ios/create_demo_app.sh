#!/bin/bash

echo "🚀 Creating BBLearning Demo App..."

# 定义项目目录
DEMO_DIR="/Users/johnqiu/coding/www/projects/bblearning/ios/BBLearningApp"
APP_NAME="BBLearningApp"

# 清理旧项目
if [ -d "$DEMO_DIR" ]; then
    echo "📁 Removing existing demo app..."
    rm -rf "$DEMO_DIR"
fi

# 创建项目目录结构
mkdir -p "$DEMO_DIR/$APP_NAME"
mkdir -p "$DEMO_DIR/$APP_NAME/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$DEMO_DIR/$APP_NAME/Preview Content/Preview Assets.xcassets"

echo "📝 Creating App files..."

# 创建 App 主文件
cat > "$DEMO_DIR/$APP_NAME/${APP_NAME}App.swift" << 'EOF'
import SwiftUI

@main
struct BBLearningAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
EOF

# 创建 ContentView
cat > "$DEMO_DIR/$APP_NAME/ContentView.swift" << 'EOF'
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("BBLearning")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("智能学习助手")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Spacer().frame(height: 40)
                
                VStack(alignment: .leading, spacing: 15) {
                    FeatureRow(icon: "book.fill", title: "海量题库", description: "涵盖各个学科的练习题")
                    FeatureRow(icon: "brain.head.profile", title: "AI 辅导", description: "智能答疑解惑")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "学习统计", description: "跟踪你的学习进度")
                    FeatureRow(icon: "star.fill", title: "收藏功能", description: "保存重要题目")
                }
                .padding()
                
                Spacer()
                
                Button(action: {
                    // TODO: Navigate to main app
                }) {
                    Text("开始学习")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .navigationTitle("欢迎")
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
EOF

# 创建 Info.plist
cat > "$DEMO_DIR/$APP_NAME/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleDisplayName</key>
    <string>BBLearning</string>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <true/>
    </dict>
    <key>UILaunchScreen</key>
    <dict/>
</dict>
</plist>
EOF

# 创建 Assets Contents.json
cat > "$DEMO_DIR/$APP_NAME/Assets.xcassets/Contents.json" << 'EOF'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

cat > "$DEMO_DIR/$APP_NAME/Assets.xcassets/AppIcon.appiconset/Contents.json" << 'EOF'
{
  "images" : [
    {
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

# 创建 project.pbxproj (简化版)
echo "📦 Creating Xcode project..."

cat > "$DEMO_DIR/$APP_NAME.xcodeproj/project.pbxproj" << 'PBXEOF'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {
		/* Begin PBXBuildFile section */
		AA0001 /* BBLearningAppApp.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA0002; };
		AA0003 /* ContentView.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA0004; };
		AA0005 /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = AA0006; };
		/* End PBXBuildFile section */

		/* Begin PBXFileReference section */
		AA0000 /* BBLearningApp.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = BBLearningApp.app; sourceTree = BUILT_PRODUCTS_DIR; };
		AA0002 /* BBLearningAppApp.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = BBLearningAppApp.swift; sourceTree = "<group>"; };
		AA0004 /* ContentView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ContentView.swift; sourceTree = "<group>"; };
		AA0006 /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };
		/* End PBXFileReference section */

		/* Begin PBXFrameworksBuildPhase section */
		AA0010 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		/* End PBXFrameworksBuildPhase section */

		/* Begin PBXGroup section */
		AA0020 = {
			isa = PBXGroup;
			children = (
				AA0021 /* BBLearningApp */,
				AA0022 /* Products */,
			);
			sourceTree = "<group>";
		};
		AA0021 /* BBLearningApp */ = {
			isa = PBXGroup;
			children = (
				AA0002 /* BBLearningAppApp.swift */,
				AA0004 /* ContentView.swift */,
				AA0006 /* Assets.xcassets */,
			);
			path = BBLearningApp;
			sourceTree = "<group>";
		};
		AA0022 /* Products */ = {
			isa = PBXGroup;
			children = (
				AA0000 /* BBLearningApp.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
		/* End PBXGroup section */

		/* Begin PBXNativeTarget section */
		AA0030 /* BBLearningApp */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = AA0031;
			buildPhases = (
				AA0032 /* Sources */,
				AA0010 /* Frameworks */,
				AA0033 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = BBLearningApp;
			productName = BBLearningApp;
			productReference = AA0000 /* BBLearningApp.app */;
			productType = "com.apple.product-type.application";
		};
		/* End PBXNativeTarget section */

		/* Begin PBXProject section */
		AA0040 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
			};
			buildConfigurationList = AA0041;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = "zh-Hans";
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				"zh-Hans",
			);
			mainGroup = AA0020;
			productRefGroup = AA0022 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				AA0030 /* BBLearningApp */,
			);
		};
		/* End PBXProject section */

		/* Begin PBXResourcesBuildPhase section */
		AA0033 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				AA0005 /* Assets.xcassets in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		/* End PBXResourcesBuildPhase section */

		/* Begin PBXSourcesBuildPhase section */
		AA0032 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				AA0003 /* ContentView.swift in Sources */,
				AA0001 /* BBLearningAppApp.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		/* End PBXSourcesBuildPhase section */

		/* Begin XCBuildConfiguration section */
		AA0050 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 15.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		AA0051 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 15.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
		AA0052 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "\"BBLearningApp/Preview Content\"";
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = BBLearningApp/Info.plist;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				IPHONEOS_DEPLOYMENT_TARGET = 15.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.bblearning.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Debug;
		};
		AA0053 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "\"BBLearningApp/Preview Content\"";
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = BBLearningApp/Info.plist;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				IPHONEOS_DEPLOYMENT_TARGET = 15.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.bblearning.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Release;
		};
		/* End XCBuildConfiguration section */

		/* Begin XCConfigurationList section */
		AA0031 /* Build configuration list for PBXNativeTarget "BBLearningApp" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				AA0052 /* Debug */,
				AA0053 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		AA0041 /* Build configuration list for PBXProject "BBLearningApp" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				AA0050 /* Debug */,
				AA0051 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		/* End XCConfigurationList section */
	};
	rootObject = AA0040 /* Project object */;
}
PBXEOF

mkdir -p "$DEMO_DIR/$APP_NAME.xcodeproj"

echo "✅ Demo app created successfully!"
echo ""
echo "📂 Location: $DEMO_DIR"
echo ""
echo "🔧 Next steps:"
echo "1. Open the project:"
echo "   open $DEMO_DIR/$APP_NAME.xcodeproj"
echo ""
echo "2. Select a simulator or device in Xcode"
echo "3. Press Cmd+R to build and run"
echo ""
