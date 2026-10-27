#!/usr/bin/env python3

import os
import sys
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

logger = logging.getLogger(__name__)


def main():
    logger.info("Starting Python application...")

    environment = os.getenv("APP_ENV", "development")
    logger.info(f"Environment: {environment}")

    try:
        logger.info("Application initialized successfully.")

        # Add your application logic here
        print("Hello from Python entrypoint!")

    except Exception as e:
        logger.error(f"Application failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()