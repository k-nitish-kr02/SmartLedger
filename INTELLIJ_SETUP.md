# IntelliJ IDEA Setup Guide - Fixing Gradle Build Errors

This guide will help you fix the 4 Gradle build errors you're seeing in IntelliJ IDEA.

## Errors You're Seeing

1. ❌ **"Found invalid Gradle JVM c..."**
2. ❌ **"JDK 23.0.1 isn't compatible with Gradle 8.7"**
3. ❌ **"Please fix JAVA_HOME environment variable"**
4. ❌ **"Could not read script 'native_modules.gradle' as it does not exist"**

## Solutions

### Fix 1: Install Node Modules (Fixes Error #4)

The React Native project needs `node_modules` installed. Run this in terminal:

```bash
cd "FrontEnd/expensetrackerapp"
npm install
```

Or if you prefer yarn:
```bash
cd "FrontEnd/expensetrackerapp"
yarn install
```

This will create the `node_modules` directory and the missing `native_modules.gradle` file.

### Fix 2: Configure IntelliJ to Use JDK 21 (Fixes Errors #1, #2, #3)

IntelliJ is currently using JDK 23.0.1, but Gradle 8.7 doesn't support it. You need to configure IntelliJ to use JDK 21.

#### Step 1: Set Project SDK

1. In IntelliJ IDEA, go to **File** → **Project Structure** (or press `Ctrl+Alt+Shift+S`)
2. Under **Project Settings** → **Project**:
   - Set **SDK** to **21** (or **21 (OpenJDK)**)
   - Set **Language level** to **21 - Record patterns, pattern matching for switch**
3. Click **Apply**

#### Step 2: Set Gradle JVM

1. Go to **File** → **Settings** (or press `Ctrl+Alt+S`)
2. Navigate to **Build, Execution, Deployment** → **Build Tools** → **Gradle**
3. Under **Gradle JVM**, select **21** (or **21 (OpenJDK)**)
   - If JDK 21 is not listed, click the dropdown and select **Download JDK...**
   - Choose **Version: 21**, **Vendor: OpenJDK** (or any vendor)
   - Click **Download**
4. Click **Apply** and **OK**

#### Step 3: Invalidate Caches

1. Go to **File** → **Invalidate Caches...**
2. Check **Clear file system cache and Local History**
3. Click **Invalidate and Restart**

#### Step 4: Re-import Gradle Project

1. Open the **Gradle** tool window (View → Tool Windows → Gradle)
2. Click the **Reload All Gradle Projects** button (circular arrow icon)
3. Wait for the sync to complete

### Fix 3: Update Gradle Version (Alternative Solution)

If you want to keep using JDK 23, you can update Gradle to version 8.10.2 or higher which supports JDK 23.

**Already done!** The `gradle-wrapper.properties` has been updated to use Gradle 8.10.2.

After updating, you still need to:
1. Re-import the Gradle project (see Fix 2, Step 4)
2. Or restart IntelliJ IDEA

### Fix 4: Set JAVA_HOME Environment Variable (Optional)

If you want to set JAVA_HOME system-wide:

**For Linux:**
```bash
# Add to ~/.bashrc or ~/.zshrc
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# Then reload
source ~/.bashrc  # or source ~/.zshrc
```

**To find your Java 21 path:**
```bash
sudo update-alternatives --config java
# Or
readlink -f $(which java)
```

**For IntelliJ IDEA specifically:**
You don't need to set JAVA_HOME system-wide if you configure it in IntelliJ settings (Fix 2, Step 2).

## Verification

After applying all fixes:

1. **Check Gradle Sync:**
   - Open Gradle tool window
   - All projects should show ✅ (green checkmark)
   - No red error icons

2. **Try Building:**
   - Go to **Build** → **Build Project** (or press `Ctrl+F9`)
   - Should complete without errors

3. **Check Build Output:**
   - View → Tool Windows → Build
   - Should show "BUILD SUCCESSFUL"

## Quick Checklist

- [ ] Installed node_modules (`npm install` in FrontEnd/expensetrackerapp)
- [ ] Set Project SDK to JDK 21 in Project Structure
- [ ] Set Gradle JVM to JDK 21 in Settings
- [ ] Invalidated caches and restarted IntelliJ
- [ ] Re-imported Gradle project
- [ ] Build succeeds

## Still Having Issues?

If errors persist:

1. **Check Java version in terminal:**
   ```bash
   java -version
   ```
   Should show Java 21 or lower.

2. **Stop Gradle daemon:**
   ```bash
   cd FrontEnd/expensetrackerapp/android
   ./gradlew --stop
   ```

3. **Clean and rebuild:**
   ```bash
   cd FrontEnd/expensetrackerapp/android
   ./gradlew clean
   ./gradlew build
   ```

4. **Check IntelliJ logs:**
   - Help → Show Log in Files
   - Look for errors related to Gradle or Java

## Notes

- **JDK 23** is too new for Gradle 8.7. Gradle 8.10.2+ supports JDK 23.
- **JDK 21** is recommended as it's the current LTS version and fully supported.
- The React Native Android build requires `node_modules` to be installed first.
- IntelliJ caches Gradle configurations, so invalidating caches is important.

