#!/bin/bash
# Production Health Check and Initialization for Render
# This script validates the runtime environment

set -e

echo "GPlay Downloader - Runtime Health Check"
echo "========================================"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 not found"
    exit 1
fi
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
echo "✓ Python: $PYTHON_VERSION"

# Check Java (required for APKEditor)
if ! command -v java &> /dev/null; then
    echo "❌ Java not found (required for APKEditor)"
    exit 1
fi
JAVA_VERSION=$(java -version 2>&1 | head -1)
echo "✓ Java: $JAVA_VERSION"

# Check APKEditor.jar
if [ ! -f "./APKEditor.jar" ]; then
    echo "❌ APKEditor.jar not found - build may have failed"
    exit 1
fi
echo "✓ APKEditor.jar: $(ls -lh APKEditor.jar | awk '{print $5}')"

# Check keystore
if [ ! -f "$HOME/.android/debug.keystore" ]; then
    echo "❌ Debug keystore not found - build may have failed"
    exit 1
fi
echo "✓ Keystore: configured"

# Check Python dependencies
echo "✓ Checking Python packages..."
python3 -c "import flask; import gunicorn; import gevent; import requests; import gpapi" 2>/dev/null || {
    echo "❌ Missing Python dependencies"
    exit 1
}

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
