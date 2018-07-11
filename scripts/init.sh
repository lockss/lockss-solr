#!/bin/sh

# Copyright (c) 2000-2018, Board of Trustees of Leland Stanford Jr. University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Mount a HDFS path if one was provided
if [ ! -z ${HDFS_HOST} ]; then
  echo "Mounting HDFS within EDINA indexer (hdfs://${HDFS_HOST:-localhost}:${HDFS_FSMD:-9000}/ -> ${LOCKSS_SOLR_HDFSMNT})"

  # Wait for HDFS to become available
  while ! nc -z ${HDFS_HOST:-localhost} ${HDFS_FSMD:-9000} ; do
      echo "Could not connect to hdfs://${HDFS_HOST:-localhost}:${HDFS_FSMD:-9000}/; retrying in 5 seconds..."
      sleep 5
  done

  # Create mount point
  mkdir -p ${LOCKSS_SOLR_HDFSMNT}

  # Attempt to mount HDFS sealed WARCs to EDINA indexer watch directory
  hadoop-fuse-dfs "dfs://${HDFS_HOST:-localhost}:${HDFS_FSMD:-9000}/" ${LOCKSS_SOLR_HDFSMNT}

  # Ensure the sealed directory exists (-p doesn't work - only used here so that mkdir is quiet if the directory already exists)
  mkdir -p ${LOCKSS_SOLR_HDFSMNT}/${REPO_BASEDIR}
  mkdir -p ${LOCKSS_SOLR_HDFSMNT}/${REPO_BASEDIR}/sealed
fi

# Indefinitely touch new files that show up in the watched directory to trigger a filesystem event in the EDINA indexer
while true; do
    find ${LOCKSS_SOLR_WATCHDIR} -newermt "-${LOCKSS_SOLR_WATCHDIR_INTERVAL} seconds" -type f -exec touch {} +
    sleep ${LOCKSS_SOLR_WATCHDIR_INTERVAL}
done &

# Start the EDINA indexer
java -jar /lockss-solr/build/libs/lockss-solr-all-1.0-SNAPSHOT.jar
