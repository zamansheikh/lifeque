#!/bin/bash

# LifeQue Build Script
# This script builds signed release APK for Google Play Store

echo "🚀 Building LifeQue Release APK..."
echo "📱 App: LifeQue - Islamic & Productivity App"
echo "🏢 Developer: Md. Shamsuzzaman (Programmer Nexus)"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Build release APK
echo "📦 Building signed release APK..."
flutter build apk --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build completed successfully!"
    echo "📍 APK Location: build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "📊 APK Info:"
    ls -lh build/app/outputs/flutter-apk/app-release.apk
    echo ""
    echo "🔐 APK is signed with release keystore"
    echo "📤 Ready for Google Play Store upload"
else
    echo ""
    echo "❌ Build failed! Check the error messages above."
    exit 1
fi
