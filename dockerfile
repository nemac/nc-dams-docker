# Get GRASS GIS
FROM osgeo/grass-gis:releasebranch_8_4-alpine AS grass-stage

# Final stage combining both
FROM qgis/qgis:latest

# Copy GRASS GIS files from grass stage
COPY --from=grass-stage /usr/local/bin/grass /usr/local/bin/
COPY --from=grass-stage /usr/local/grass* /usr/local/grass/

# Install python3-venv and other dependencies
RUN apt-get update && apt-get install -y \
    python3-venv \
    g++ \
    make \
    git \
    cmake \
    libgdal-dev \
    libproj-dev \
    libzstd-dev \
    && apt-get clean

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

# Set up GRASS GIS environment, location, mapset, and CRS
RUN mkdir -p /grassdata/my_location/PERMANENT && \
    grass -c EPSG:4326 /grassdata/my_location/PERMANENT --exec g.mapset -c mapset=my_mapset location=my_location

# Install the desired GRASS GIS addon
RUN grass /grassdata/my_location/my_mapset --exec g.extension extension=r.shade

# Install r.damflood
RUN GISBASE=/usr/local/grass \
    PATH=/usr/local/grass/bin:/usr/local/grass/scripts:$PATH \
    LD_LIBRARY_PATH=/usr/local/grass/lib:$LD_LIBRARY_PATH \
    grass --text -e -c /tmp/grassdata && \
    g.extension extension=r.damflood

# Create a script to run both version checks
RUN echo '#!/bin/bash\necho "QGIS Version:"\nqgis_process -v\necho "\nGRASS GIS Version:"\ngrass -v' > /usr/local/bin/version-check.sh && \
    chmod +x /usr/local/bin/version-check.sh
# 
RUN echo '#!/bin/bash\necho "grass --text -e -c /tmp/grassdata/loc1/mapset --exec g.extension extension=r.damflood"'
# Copy and set up your test file
COPY test_file.py /app/
WORKDIR /app

# Use the virtual environment's Python to run your script
CMD ["/opt/venv/bin/python3", "test_file.py"]
