#!/bin/bash
# Render.com Build Script for GPlay APK Downloader
# This runs during the build phase before the app starts

set -e

echo "======================================"
echo "  GPlay Downloader - Render Build"
echo "======================================"
echo ""

# Python dependencies
echo "[1/4] Installing Python dependencies..."
if ! pip install --upgrade pip > /dev/null 2>&1; then
    echo "⚠ Failed to upgrade pip (non-critical)"
else
    echo "✓ pip upgraded"
fi
if ! pip install -r requirements.txt > /dev/null 2>&1; then
    echo "❌ Failed to install requirements"
    exit 1
fi
echo "✓ Dependencies installed"

# APKEditor.jar
echo "[2/4] Downloading APKEditor..."
APKEDITOR_JAR="./APKEditor.jar"
if [ ! -f "$APKEDITOR_JAR" ]; then
    if curl -sL -o "$APKEDITOR_JAR" \
        "https://github.com/REAndroid/APKEditor/releases/download/V1.4.1/APKEditor-1.4.1.jar" 2>/dev/null; then
        if [ -f "$APKEDITOR_JAR" ] && [ -s "$APKEDITOR_JAR" ]; then
            echo "✓ Downloaded APKEditor: $(ls -lh "$APKEDITOR_JAR" | awk '{print $5}')"
        else
            echo "⚠ APKEditor download empty (will use simple merge)"
        fi
    else
        echo "⚠ APKEditor download failed (will use simple merge)"
    fi
else
    echo "✓ APKEditor already exists: $(ls -lh "$APKEDITOR_JAR" | awk '{print $5}')"
fi

# Debug keystore for APK signing (optional - will be created at runtime if needed)
echo "[3/4] Setting up signing keystore..."
KEYSTORE_DIR="$HOME/.android"
KEYSTORE_FILE="$KEYSTORE_DIR/debug.keystore"
mkdir -p "$KEYSTORE_DIR"

if [ ! -f "$KEYSTORE_FILE" ]; then
    if command -v keytool &> /dev/null; then
        if keytool -genkey -v -keystore "$KEYSTORE_FILE" \
            -storepass android -alias androiddebugkey -keypass android \
            -keyalg RSA -keysize 2048 -validity 10000 \
            -dname "CN=Android Debug,O=Android,C=US" 2>&1 | tail -3; then
            echo "✓ Keystore created"
        else
            echo "⚠ Keystore creation failed (will be created at runtime if needed)"
        fi
    else
        echo "⚠ keytool not found (Java not available - signing will be optional)"
    fi
else
    echo "✓ Keystore already exists"
fi

# Create initial auth cache if not present
echo "[4/4] Initializing cache directories..."
AUTH_CACHE_DIR="$HOME"
mkdir -p "$AUTH_CACHE_DIR"
touch "$AUTH_CACHE_DIR/.gplay-auth.json" 2>/dev/null || true
touch "$AUTH_CACHE_DIR/.gplay-auth-armv7.json" 2>/dev/null || true
touch "$AUTH_CACHE_DIR/.gplay-download-count" 2>/dev/null || true
echo "✓ Cache initialized"

echo ""
echo "======================================"
echo "  Build Complete!"
echo "======================================"
echo ""
echo "Running health checks..."
bash health-check.sh

