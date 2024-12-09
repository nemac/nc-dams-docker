# Get GRASS GIS
FROM osgeo/grass-gis:releasebranch_8_4-alpine AS grass-stage

# Final stage combining both
FROM qgis/qgis:latest

# Copy GRASS GIS files from grass stage
COPY --from=grass-stage /usr/local/bin/grass /usr/local/bin/
COPY --from=grass-stage /usr/local/grass* /usr/local/grass/

# Install python3-venv
RUN apt-get update && apt-get install -y python3-venv

# Create and activate virtual environment
RUN python3 -m venv /opt/venv --system-site-packages
ENV PATH="/opt/venv/bin:$PATH"

# Set environment variables for GRASS (fixing undefined variables)
ENV GISBASE=/usr/local/grass
ENV PATH="/usr/local/grass/bin:/usr/local/grass/scripts:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/grass/lib:${LD_LIBRARY_PATH:-}"
ENV GRASS_PYTHON=/opt/venv/bin/python3
ENV PYTHONPATH="/usr/local/grass/etc/python:${PYTHONPATH:-}"

# Install grass-session in the virtual environment
RUN pip install grass-session

# Create a script to run both version checks
RUN echo '#!/bin/bash\necho "QGIS Version:"\nqgis_process -v\necho "\nGRASS GIS Version:"\ngrass -v' > /usr/local/bin/version-check.sh && \
    chmod +x /usr/local/bin/version-check.sh

# Copy and set up your test file
COPY test_file.py /app/
WORKDIR /app

# Use the virtual environment's Python to run your script
CMD ["/opt/venv/bin/python3", "test_file.py"]
