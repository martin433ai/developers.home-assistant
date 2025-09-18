#!/usr/bin/env python3
"""
Main entry point for the EAD Networks server.
This file imports and runs the Flask application from the parent directory.
"""

import sys
import os

# Add the parent directory to the Python path so we can import app.py
parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, parent_dir)

# Import the Flask app from app.py
from app import app, load_config, logger, CONFIG_DIR
import json
import logging

if __name__ == "__main__":
    config = load_config()

    # Set up logging to file
    log_file = os.path.join(CONFIG_DIR, "server.log")
    file_handler = logging.FileHandler(log_file)
    file_handler.setFormatter(
        logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
    )
    logger.addHandler(file_handler)

    logger.info("Starting EAD Networks Configuration Server via main.py")
    logger.info(f"Config directory: {CONFIG_DIR}")
    logger.info(f"Configuration loaded: {json.dumps(config, indent=2)}")

    app.run(
        host=config["server"]["host"],
        port=config["server"]["port"],
        debug=config["server"]["debug"],
    )
