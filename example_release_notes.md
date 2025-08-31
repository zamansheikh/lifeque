# Example Release Notes for RemindMe

Here are some example release notes you can use for testing or inspiration:

## 🚀 RemindMe v1.0.6+6

### ✨ New Features
- 🕌 **Islamic Prayer Times**: Added comprehensive prayer times with GPS location support
- 📍 **Smart Location**: Automatic GPS detection with manual location fallback
- ⚙️ **Prayer Settings**: Configurable calculation methods (Karachi, Muslim World League, etc.)
- 💾 **Settings Persistence**: Location and prayer preferences saved using SharedPreferences
- 🧭 **Qibla Direction**: Built-in Qibla compass for prayer direction

### 🛠️ Improvements
- 📱 Enhanced UI with modern Material Design 3
- 🔄 Improved update system with GitHub integration
- 🎯 Better navigation with drawer integration
- 📊 Optimized performance for prayer time calculations

### 🐛 Bug Fixes
- 📅 Fixed critical date picker crash in task editing
- 🔄 Resolved infinite loading dialog issues during updates
- 📍 Fixed location permission handling
- 🎨 Improved UI consistency across all screens

### 📥 Installation
1. Download the APK file below
2. Enable "Install from unknown sources" in Android settings
3. Install the APK file
4. Grant location permissions for prayer times
5. Enjoy the new features!

### 🔄 Update Notes
- This version requires location permissions for prayer times feature
- First-time setup will request GPS permissions
- Previous settings and tasks are preserved during update

### 🐛 Found a Bug?
Report issues at: https://github.com/zamansheikh/remindme/issues

---

## How to Use These Release Notes

### Option 1: Manual GitHub Release
1. Go to https://github.com/zamansheikh/remindme/releases
2. Click "Edit" on any release
3. Copy and paste the content above into the description field
4. Modify as needed for the specific version
5. Save the release

### Option 2: Automatic via GitHub Actions
The GitHub Actions workflow has been updated to automatically include:
- Auto-generated release notes from commits
- Structured release information
- Installation instructions
- Bug report links

### Testing the Release Notes in App
1. Temporarily lower your app version in `pubspec.yaml`
2. Build and install the app
3. Use "Check for Updates" in the About dialog
4. You should see the release notes in the update dialog

### Release Notes Best Practices
- Use emojis for visual appeal (🚀 ✨ 🛠️ 🐛)
- Group changes by category (Features, Improvements, Bug Fixes)
- Include installation instructions
- Mention any breaking changes or required permissions
- Provide links for bug reports
- Keep it concise but informative
