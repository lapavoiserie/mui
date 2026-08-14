#!/bin/bash
# Build the kitchen sink for Android, assemble an APK by hand, install it and
# launch it.
#
# No Gradle. The Android Gradle Plugin resolves itself from the network on first
# use, and every step it performs is one command here: aapt2 links the resources
# and the manifest, javac and d8 turn the two Java classes into a dex, the NDK
# compiles the generated C++ and the hxcpp runtime into one shared library, and
# apksigner signs it with a throwaway key. The whole thing is legible, offline,
# and the same shape as the iOS and SailfishOS builds -- Haxe generates C++ and
# something else does the compiling.
set -e

HERE="$(cd "$(dirname "$0")" && pwd)"
SDK="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
NDK="${PUI_NDK:-$SDK/ndk/27.1.12297006}"
BUILD_TOOLS="$SDK/build-tools/35.0.0"
PLATFORM="$SDK/platforms/android-36/android.jar"
HXCPP="$(haxelib libpath hxcpp)"
PUI="$(haxelib libpath pui)"
JAVA_SRC="$PUI/src/pui/backend/android/java"
ABI="arm64-v8a"
BUILD="$HERE/build/android"

echo "-- generating C++"
cd "$HERE"
haxe build-pui-android.hxml

echo "-- compiling for $ABI"
rm -rf "$BUILD"
mkdir -p "$BUILD/obj" "$BUILD/lib/$ABI" "$BUILD/classes" "$BUILD/res/values"

CXX="$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android24-clang++"
FLAGS=(-O1 -fPIC -fno-strict-aliasing
	-DHX_ANDROID -DANDROID -DHXCPP_M64 -DHXCPP_ARM64
	# The collector picks its register-scanning assembly from the platform
	# macros, and has no arm64 path of its own; hxcpp keeps a setjmp one for
	# exactly this.
	-DHXCPP_CAPTURE_SETJMP
	# Exactly the defines codegen ran with, and no more -- build/…/Options.txt is
	# the authority. HXCPP_GC_GENERATIONAL here would build a collector expecting
	# write barriers the generated code never emits.
	-DHXCPP_VISIT_ALLOCS -DHX_SMART_STRINGS -DHXCPP_API_LEVEL=430
	-I"$HXCPP/include" -I"$PUI/src/pui/backend/android/native"
	-I"$HERE/build/pui-android/include" -I"$HERE/build/pui-android/src"
	-std=c++11 -Wno-everything)

SOURCES=()
while read -r f; do SOURCES+=("$HXCPP/$f"); done <<'EOF'
src/Array.cpp
src/Dynamic.cpp
src/Enum.cpp
src/Math.cpp
src/String.cpp
src/hx/Anon.cpp
src/hx/Boot.cpp
src/hx/CFFI.cpp
src/hx/Class.cpp
src/hx/Date.cpp
src/hx/Debug.cpp
src/hx/Hash.cpp
src/hx/Interface.cpp
src/hx/Lib.cpp
src/hx/Object.cpp
src/hx/RunLibs.cpp
src/hx/StdLibs.cpp
src/hx/Thread.cpp
src/hx/gc/GcRegCapture.cpp
src/hx/gc/GcCommon.cpp
src/hx/gc/Immix.cpp
src/hx/libs/std/Process.cpp
src/hx/libs/std/Socket.cpp
src/hx/libs/std/Random.cpp
src/hx/libs/std/File.cpp
src/hx/libs/std/Sys.cpp
EOF

# `__lib__.cpp` and `__main__.cpp` both define the entry point; on Android the
# one worth having is `__main__.cpp`, because that is where HxcppMain.h puts the
# JNI entry `Java_org_haxe_HXCPP_main` the activity calls.
while IFS= read -r f; do SOURCES+=("$f"); done \
	< <(find "$HERE/build/pui-android/src" -name '*.cpp' ! -name '__lib__.cpp')
SOURCES+=("$PUI/src/pui/backend/android/native/pui_and.cpp")

n=0
for s in "${SOURCES[@]}"; do
	n=$((n + 1))
	"$CXX" "${FLAGS[@]}" -c "$s" -o "$BUILD/obj/$n.o" &
	if [ $((n % 12)) -eq 0 ]; then wait; fi
done
wait

echo "-- linking libpui.so"
"$CXX" -shared "$BUILD"/obj/*.o -llog -o "$BUILD/lib/$ABI/libpui.so"
cp "$NDK/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" \
	"$BUILD/lib/$ABI/"

echo "-- java"
cat > "$BUILD/AndroidManifest.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
	package="com.lapavoiserie.pui.kitchensink">
	<uses-sdk android:minSdkVersion="24" android:targetSdkVersion="34" />
	<application android:label="Kitchen Sink" android:hasCode="true"
		android:theme="@android:style/Theme.Material.NoActionBar">
		<activity android:name="com.lapavoiserie.pui.PuiActivity"
			android:exported="true"
			android:configChanges="orientation|screenSize|keyboardHidden|uiMode"
			android:windowSoftInputMode="adjustResize">
			<intent-filter>
				<action android:name="android.intent.action.MAIN" />
				<category android:name="android.intent.category.LAUNCHER" />
			</intent-filter>
		</activity>
	</application>
</manifest>
XML

javac -source 8 -target 8 -nowarn -bootclasspath "$PLATFORM" -classpath "$PLATFORM" \
	-d "$BUILD/classes" \
	"$JAVA_SRC/com/lapavoiserie/pui/PuiView.java" \
	"$JAVA_SRC/com/lapavoiserie/pui/PuiActivity.java" \
	"$JAVA_SRC/org/haxe/HXCPP.java" 2>&1 | grep -v "^Note:" || true

"$BUILD_TOOLS/d8" --min-api 24 --output "$BUILD" \
	$(find "$BUILD/classes" -name '*.class') >/dev/null

echo "-- packaging"
"$BUILD_TOOLS/aapt2" compile --dir "$BUILD/res" -o "$BUILD/res.zip" >/dev/null
"$BUILD_TOOLS/aapt2" link -o "$BUILD/base.apk" -I "$PLATFORM" \
	--manifest "$BUILD/AndroidManifest.xml" "$BUILD/res.zip" \
	--min-sdk-version 24 --target-sdk-version 34 >/dev/null

cd "$BUILD"
zip -q base.apk classes.dex
zip -q base.apk "lib/$ABI/libpui.so" "lib/$ABI/libc++_shared.so"

KEYSTORE="$HERE/build/pui-debug.keystore"
if [ ! -f "$KEYSTORE" ]; then
	keytool -genkeypair -keystore "$KEYSTORE" -alias pui -storepass password \
		-keypass password -keyalg RSA -keysize 2048 -validity 10000 \
		-dname "CN=pui" >/dev/null 2>&1
fi

"$BUILD_TOOLS/zipalign" -f 4 base.apk aligned.apk
"$BUILD_TOOLS/apksigner" sign --ks "$KEYSTORE" --ks-pass pass:password \
	--out KitchenSink.apk aligned.apk

echo "-- installing"
"$SDK/platform-tools/adb" install -r KitchenSink.apk
"$SDK/platform-tools/adb" shell am start -n \
	com.lapavoiserie.pui.kitchensink/com.lapavoiserie.pui.PuiActivity
