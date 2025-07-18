FROM mariadb:lts

# Install system dependencies
RUN apt-get update && apt-get install -y pv

# Cleaning
RUN apt-get clean && rm -rf /var/lib/apt/lists/*