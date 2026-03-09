#!/bin/bash

# Function to increment version
increment_version() {
    local version=$1
    local position=$2
    
    IFS='.' read -ra VERSION_PARTS <<< "${version%+*}"
    local build_number="${version#*+}"
    
    # Increment build number
    build_number=$((build_number + 1))
    
    # Increment version based on position (1=major, 2=minor, 3=patch)
    case $position in
        1)
            VERSION_PARTS[0]=$((VERSION_PARTS[0] + 1))
            VERSION_PARTS[1]=0
            VERSION_PARTS[2]=0
            ;;
        2)
            VERSION_PARTS[1]=$((VERSION_PARTS[1] + 1))
            VERSION_PARTS[2]=0
            ;;
        3)
            VERSION_PARTS[2]=$((VERSION_PARTS[2] + 1))
            ;;
    esac
    
    echo "${VERSION_PARTS[0]}.${VERSION_PARTS[1]}.${VERSION_PARTS[2]}+${build_number}"
}

# Read current version from pubspec.yaml
CURRENT_VERSION=$(grep 'version:' pubspec.yaml | cut -d' ' -f2)

# Ask for version bump type
echo "Current version is $CURRENT_VERSION"
echo "Select version bump type:"
echo "1) Major (x.0.0) - Breaking changes"
echo "2) Minor (0.x.0) - New features"
echo "3) Patch (0.0.x) - Bug fixes"
read -p "Enter choice (1-3): " BUMP_TYPE

# Validate input
if [[ ! "$BUMP_TYPE" =~ ^[1-3]$ ]]; then
    echo "❌ Invalid choice. Please enter 1, 2, or 3."
    exit 1
fi

# Get new version
NEW_VERSION=$(increment_version "$CURRENT_VERSION" "$BUMP_TYPE")

echo "🔄 Updating version from $CURRENT_VERSION to $NEW_VERSION"

# Update pubspec.yaml
sed -i '' "s/version: .*/version: $NEW_VERSION/" pubspec.yaml
echo "✅ Updated pubspec.yaml"

# Create version.json in root directory
cat > version.json << EOF
{
  "version": "${NEW_VERSION%+*}",
  "build_number": "${NEW_VERSION#*+}",
  "changelog": "- Bug fixes and improvements",
  "force_update": false,
  "download_url": "https://tascesalary.com.ng/download.html"
}
EOF
echo "✅ Created version.json in root directory"

# Create download folder
mkdir -p download

# Create version.json in download directory
cat > download/version.json << EOF
{
  "version": "${NEW_VERSION%+*}",
  "build_number": "${NEW_VERSION#*+}",
  "changelog": "- Bug fixes and improvements",
  "force_update": false,
  "download_url": "https://tascesalary.com.ng/download.html"
}
EOF
echo "✅ Created version.json in download directory"

# Build APK
echo "🔨 Building APK..."
flutter build apk --split-per-abi --release

# Check if split APKs were created
if [ ! -f "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" ] && [ ! -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo "⚠️  Split APK build failed, trying universal APK..."
    flutter build apk --release
fi

# Copy APK files with error handling
echo "📁 Copying APK files..."

# Check and copy each architecture
if [ -f "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" ]; then
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk download/tasce_arm64-v8a_${NEW_VERSION%+*}.apk
    echo "✅ Copied ARM64 APK"
else
    echo "❌ ARM64 APK not found"
fi

if [ -f "build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk" ]; then
cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk download/tasce_armeabi-v7a_${NEW_VERSION%+*}.apk
    echo "✅ Copied ARM APK"
else
    echo "❌ ARM APK not found"
fi

if [ -f "build/app/outputs/flutter-apk/app-x86_64-release.apk" ]; then
cp build/app/outputs/flutter-apk/app-x86_64-release.apk download/tasce_x86_64_${NEW_VERSION%+*}.apk
    echo "✅ Copied x86_64 APK"
else
    echo "❌ x86_64 APK not found"
fi

# Also try to copy the universal APK if split APKs failed
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    cp build/app/outputs/flutter-apk/app-release.apk download/tasce_universal_${NEW_VERSION%+*}.apk
    echo "✅ Copied Universal APK"
    echo "ℹ️  Note: Universal APK works on all devices but is larger in size"
fi

echo ""
echo "🎉 Version bump completed successfully!"
echo "📱 New version: $NEW_VERSION"
echo "📁 Files created in download folder:"
ls -la download/
echo ""
echo "🚀 Ready for deployment!"