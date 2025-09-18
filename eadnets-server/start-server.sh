#!/bin/bash
set -e

echo "🌐 Starting EAD Networks Configuration Server..."

# Check if running in the correct directory
if [[ ! -f "app.py" ]]; then
    echo "Error: app.py not found. Make sure you're running this from the eadnets-server directory."
    exit 1
fi

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is required but not installed."
    exit 1
fi

# Create virtual environment if it doesn't exist
if [[ ! -d "venv" ]]; then
    echo "📦 Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "⚡ Activating virtual environment..."
source venv/bin/activate

# Install/upgrade dependencies
echo "📚 Installing dependencies..."
pip install -r requirements.txt

# Check if configuration directory exists
CONFIG_DIR="$HOME/.eadnets"
if [[ ! -d "$CONFIG_DIR" ]]; then
    echo "📁 Creating configuration directory: $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
fi

# Start the server
echo "🚀 Starting EAD Networks Configuration Server on http://localhost:8080"
echo "   You can access the web interface at: http://localhost:8080"
echo "   Press Ctrl+C to stop the server"
echo ""

python3 app.py