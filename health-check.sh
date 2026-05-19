#!/bin/bash
# Production Health Check for Render (informational only - no exit on failure)
# This script validates the runtime environment

echo "GPlay Downloader - Runtime Health Check"
echo "========================================"

# Check Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    echo "✓ Python: $PYTHON_VERSION"
else
    echo "⚠ Python3 not found"
fi

# Check Java (optional - will fall back to simple merge)
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -1)
    echo "✓ Java: $JAVA_VERSION (APKEditor available)"
else
    echo "⚠ Java not found (will use simple APK merge)"
fi

# Check APKEditor.jar (optional)
if [ -f "./APKEditor.jar" ]; then
    echo "✓ APKEditor.jar: $(ls -lh APKEditor.jar | awk '{print $5}')"
else
    echo "⚠ APKEditor.jar not found (will use simple merge)"
fi

# Check keystore (optional)
if [ -f "$HOME/.android/debug.keystore" ]; then
    echo "✓ Keystore: configured"
else
    echo "⚠ Debug keystore not found (signing will be optional)"
fi

# Check Python dependencies
if python3 -c "import flask; import gunicorn; import gevent; import requests; import gpapi" 2>/dev/null; then
    echo "✓ Python packages: OK"
else
    echo "❌ Missing required Python packages"
    exit 1
fi

# Check temp directory
TEMP_DIR=$(python3 -c "import tempfile; print(tempfile.gettempdir())")
if [ ! -w "$TEMP_DIR" ]; then
    echo "❌ Temp directory not writable: $TEMP_DIR"
    exit 1
fi
echo "✓ Temp directory: $TEMP_DIR (writable)"

# Check auth cache directories
AUTH_DIR="$HOME"
if [ ! -w "$AUTH_DIR" ]; then
    echo "❌ Home directory not writable: $AUTH_DIR"
    exit 1
fi
echo "✓ Cache directory: $AUTH_DIR (writable)"

# Ensure cache files exist
touch "$HOME/.gplay-auth.json" 2>/dev/null || true
touch "$HOME/.gplay-auth-armv7.json" 2>/dev/null || true
touch "$HOME/.gplay-download-count" 2>/dev/null || true
echo "✓ Cache files initialized"

# Check static files
if [ ! -d "./public" ]; then
    echo "❌ Static files (public/) not found"
    exit 1
fi
echo "✓ Static files: configured"

echo ""
echo "========================================"
echo "✓ All checks passed - ready to start!"
echo "========================================"
