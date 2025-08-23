# KOEMO iOS Code Signing Issues - Troubleshooting Guide

## Current Status
- **Bundle Identifier**: `com.koemo.demo` ✅
- **Development Team**: `DB9C77YJ95` (soichiro kogen Personal Team) ✅
- **Signing Identity**: `Apple Development: soichiro kogen (LND37T949A)` ✅
- **Simulator Build**: Working ✅
- **Device Build**: Failing ❌

## Issues Identified

### 1. Primary Issue: Keychain Access Error (`errSecInternalComponent`)
**Error**: `errSecInternalComponent` during code signing of frameworks
**Cause**: macOS Keychain access issues preventing proper code signing

### 2. Device Build Signing Failure
**Error**: Code signing fails when building for physical device
**Cause**: Keychain unable to access signing certificate during build process

## Solutions

### Solution 1: Fix Keychain Access Issues (Most Critical)

#### Step 1: Unlock and Reset Keychain
```bash
# Unlock the login keychain
security unlock-keychain ~/Library/Keychains/login.keychain-db

# If issues persist, delete and recreate keychain (CAUTION: This will remove all stored passwords)
# security delete-keychain ~/Library/Keychains/login.keychain-db
# security create-keychain -p "" ~/Library/Keychains/login.keychain-db
# security set-keychain-settings ~/Library/Keychains/login.keychain-db
```

#### Step 2: Re-import Development Certificate
```bash
# Check current certificates
security find-identity -v -p codesigning

# If certificate is missing or corrupted, re-import from Xcode
# Go to Xcode > Preferences > Accounts > View Details > Download All Profiles
```

### Solution 2: Xcode Project Configuration

#### Step 1: Verify Automatic Signing is Enabled
In Xcode:
1. Select KOEMO project
2. Select KOEMO target
3. Go to "Signing & Capabilities" tab
4. Ensure "Automatically manage signing" is checked ✅
5. Verify Team is set to "soichiro kogen (Personal Team)"
6. Verify Bundle Identifier is "com.koemo.demo"

#### Step 2: Clean and Reset Derived Data
```bash
# Clean project
xcodebuild -workspace KOEMO.xcworkspace -scheme KOEMO clean

# Remove derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/KOEMO-*
```

### Solution 3: Build with Provisioning Updates

#### Command Line Build (Recommended)
```bash
# Build for device with automatic provisioning updates
xcodebuild -workspace KOEMO.xcworkspace \
           -scheme KOEMO \
           -destination 'generic/platform=iOS' \
           -allowProvisioningUpdates \
           clean build
```

#### Alternative: Build for Specific Device
```bash
# First, list available devices
xcrun xctrace list devices

# Build for specific connected device (replace with your device UDID)
xcodebuild -workspace KOEMO.xcworkspace \
           -scheme KOEMO \
           -destination 'platform=iOS,id=YOUR_DEVICE_UDID' \
           -allowProvisioningUpdates \
           build
```

### Solution 4: CocoaPods Framework Signing Issues

#### Update Podfile to Handle Code Signing
Add to your `Podfile`:
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
    end
  end
end
```

Then run:
```bash
pod install
```

### Solution 5: Xcode GUI Troubleshooting Steps

1. **Open Xcode**
   ```bash
   open KOEMO.xcworkspace
   ```

2. **Check Signing Status**
   - Product → Archive (or Build for Device)
   - If prompted, sign in to Apple ID
   - Allow Xcode to create/download provisioning profiles

3. **Manual Profile Management** (if automatic fails)
   - Uncheck "Automatically manage signing"
   - Go to Apple Developer Portal
   - Create App ID for `com.koemo.demo`
   - Create Development Provisioning Profile
   - Download and install profile
   - Select profile in Xcode

## Testing the Fix

### Test 1: Simulator Build (Should work)
```bash
xcodebuild -workspace KOEMO.xcworkspace -scheme KOEMO -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### Test 2: Device Build (The main test)
```bash
xcodebuild -workspace KOEMO.xcworkspace -scheme KOEMO -destination 'generic/platform=iOS' -allowProvisioningUpdates build
```

## Common Additional Issues & Solutions

### Issue: "No matching provisioning profiles found"
**Solution**: Use `-allowProvisioningUpdates` flag or manually create profiles

### Issue: "Apple ID authentication failed"
**Solution**: 
1. Sign in to Xcode with Apple ID
2. Or use App Store Connect API keys for CI/CD

### Issue: "Development team not found"
**Solution**: Verify team ID matches certificate OU field

### Issue: Certificate expired
**Solution**: 
1. Go to Xcode → Preferences → Accounts
2. Select Apple ID → View Details
3. Click "Download All Profiles"

## Next Steps

1. **Immediate**: Try Solution 1 (Keychain fix) + Solution 3 (Build command)
2. **If still failing**: Try Solution 4 (CocoaPods fix)
3. **Last resort**: Solution 5 (Manual profile management)

## Verification Commands

```bash
# Check keychain status
security list-keychains

# Check available certificates
security find-identity -v -p codesigning

# Check project settings
xcodebuild -workspace KOEMO.xcworkspace -scheme KOEMO -showBuildSettings | grep -E "DEVELOPMENT_TEAM|CODE_SIGN|PRODUCT_BUNDLE_IDENTIFIER"

# List connected devices
xcrun xctrace list devices
```