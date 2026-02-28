# 🔧 Android Build & Deployment Troubleshooting Guide

## Current Issues & Solutions

### Issue 1: NDK Not Configured ✅ FIXED
**Problem**: `NDK not configured. Download it with SDK manager. Preferred NDK version is '27.0.12077973'`

**Solution Applied**: Updated `android/app/build.gradle.kts` to explicitly specify NDK version:
```gradle
ndkVersion = "27.0.12077973"
```

### Issue 2: Network Connection Issues
**Problem**: Gradle/SDK manager trying to download Android components but connection refused

**Solution**: 
- Android emulator is trying to download manifests over network
- Local cache might be incomplete
- **Recommended**: Use **Windows Desktop** or **Chrome Web** platform for development instead

---

## 🚀 How to Run the App

### Option 1: Run on Windows Desktop (RECOMMENDED ✨)
Fastest development experience, no emulator needed:

```bash
cd C:\Users\samruddhikhilari\Desktop\VIT\smile_please\Hackathon\demo
flutter run -d windows
```

**Why Windows?**
- ✅ Direct native compilation (no Android NDK needed)
- ✅ Much faster builds (2-5 minutes vs 10-15 minutes)
- ✅ No emulator overhead
- ✅ Full debugging support
- ✅ Hot reload works perfectly

### Option 2: Run on Chrome Web
Very fast, good for UI testing:

```bash
flutter run -d chrome
```

**Why Chrome Web?**
- ✅ No compilation needed after code changes
- ✅ ~30 seconds to see changes
- ✅ Can test responsive UI
- ⚠️ No native device dialogs (camera, permissions, etc.)

### Option 3: Run on Android Emulator
Most realistic but slow, requires NDK setup:

```bash
flutter run -d emulator-5554
```

**Requirements**:
- [ ] Android SDK properly installed
- [ ] NDK 27.0.12077973 downloaded via SDK Manager
- [ ] Android Emulator running
- [ ] ANDROID_HOME environment variable set

---

## 📝 Step-by-Step: Running on Windows

```bash
# 1. Navigate to project
cd C:\Users\samruddhikhilari\Desktop\VIT\smile_please\Hackathon\demo

# 2. Clean previous builds
flutter clean

# 3. Get dependencies
flutter pub get

# 4. Generate code files
dart run build_runner build --delete-conflicting-outputs

# 5. Run on Windows
flutter run -d windows

# ✅ App should launch in ~3-5 minutes!
```

---

## 🔍 Verification Checklist

After running the app, verify:

- [ ] **Splash screen appears** with animated logo
- [ ] **App navigates** through screens
- [ ] **No red/yellow error screens**
- [ ] **Console shows "All services initialized"**
- [ ] **Routes work** when tapping navigation

---

## 📊 Available Devices

Check what's available:

```bash
flutter devices

# Output should show:
# Windows (desktop) - Available
# Chrome            - Available  
# sdk gphone64      - (emulator, requires setup)
```

---

## 🐛 Debugging

### If Windows build fails:
```bash
flutter doctor -v  # Check Visual Studio installation
flutter run -d windows -v  # Verbose output
```

### If dependencies missing:
```bash
flutter pub get
flutter pub upgrade  # Update to latest compatible versions
```

### If code generation fails:
```bash
# Clear build cache
dart run build_runner clean

# Rebuild
dart run build_runner build --delete-conflicting-outputs
```

### If hot reload doesn't work:
```bash
# Restart the app
# Press 'R' in terminal (full reload)
# Or press 'r' for hot reload
```

---

## 📱 Android Emulator Setup (Optional, for later)

If you want to use Android emulator:

```bash
# 1. Open Android Studio SDK Manager
# Settings → Appearance & Behavior → System Settings → Android SDK
# 
# 2. Click "SDK Tools" tab
# 
# 3. Check:
#    ✅ Android SDK Build-Tools (36.0.0+)
#    ✅ Android Emulator
#    ✅ NDK (Side by side) → 27.0.12077973
#    ✅ Android SDK Command-line Tools
#
# 4. Click "Apply" → Download & Install
#
# 5. Create AVD (Virtual Device)
# Tools → Device Manager → Create Device
#
# 6. Run emulator:
# flutter emulators --launch Emulator-1
#
# 7. Then run:
# flutter run -d emulator-5554
```

---

## ✅ What Works Now

After any fixes:

- ✅ Code generation (freezed, json_serializable)
- ✅ Route navigation (16+ screens configured)
- ✅ HTTP client setup (Dio with interceptors)
- ✅ Exception hierarchy (8 types)
- ✅ All screens implemented
- ✅ Riverpod state management setup
- ✅ Material Design 3 theme

---

## 🎯 Next Steps (Development)

Once app runs successfully:

1. **Explore the UI** - Navigate through all screens
2. **Check console** - Look for any warnings or errors
3. **Review file structure** - Understand the MVVM organization
4. **Start Phase 1** - Begin with `AuthRepository` implementation
5. **Follow IMPLEMENTATION_GUIDE.md** - 5-phase roadmap

---

## 💡 Pro Tips

1. **Hot Reload**: Press 'r' during dev to see changes instantly
2. **Hot Restart**: Press 'R' to restart app with new code
3. **Verbose Mode**: Add `-v` flag for detailed logs
4. **DevTools**: Run `flutter run -d windows --devtools` for debugging
5. **Multiple Emulators**: Can run different versions in parallel

---

## 📞 If Issues Persist

1. **Clear Everything**:
   ```bash
   flutter clean
   rm -r .dart_tool
   flutter pub get
   ```

2. **Reinstall Flutter** (if needed):
   ```bash
   flutter version  # Check current
   flutter upgrade  # Update to latest
   ```

3. **Check Environment**:
   ```bash
   flutter doctor  # Full diagnosis
   ```

---

**Recommended**: Start with **Windows Desktop** - it's the fastest path to seeing your working app! 🎉

Once verified on Windows, you can setup Android emulator later if needed for testing native features.
