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

# TODO: This is a workaround to get the text indexer to notice new WARCs. The correct fix is to wrap the indexer as REST
# service or get it to listen to JMS queues. We are aware there are all sorts of boundary conditions and other subtle
# problems with this workaround.

# Create timestamp directory structure for persistence (-p doesn't appear to work via FUSE; used here to quiet mkdir if
# the directory already exists)
mkdir -p ${LOCKSS_SOLR_HDFSMNT}/${REPO_BASEDIR}
mkdir -p ${LOCKSS_SOLR_HDFSMNT}/${REPO_BASEDIR}/timestamps
TIMESTAMP=${LOCKSS_SOLR_HDFSMNT}/${REPO_BASEDIR}/timestamps/edina-indexer.timestamp

# Wait until the EDINA indexer service is running
while ! ps | grep -q java; do
    echo "Waiting for EDINA indexer to start up; checking again in 5 seconds..."
    sleep 5
done

# Catch-up to present moment depending on whether a timestamp exists
if [ -e $TIMESTAMP ]; then
    # YES: Find any files newer than the last time we touched files
    find ${LOCKSS_SOLR_WATCHDIR} -newer ${TIMESTAMP} -type f -exec touch {} +
    date > ${TIMESTAMP}
else
    # NO: First time running - touch any existing files
    find ${LOCKSS_SOLR_WATCHDIR} -type f -exec touch {} +
fi

# Wait so that we don't immediately reindex any files that happened to show up within last interval amount of time
sleep ${LOCKSS_SOLR_WATCHDIR_INTERVAL}

# Indefinitely touch new files that show up in the watched directory to trigger a filesystem event in the EDINA indexer
while true; do
    find ${LOCKSS_SOLR_WATCHDIR} -newermt "-${LOCKSS_SOLR_WATCHDIR_INTERVAL} seconds" -type f -exec touch {} +
    date > ${TIMESTAMP}
    sleep ${LOCKSS_SOLR_WATCHDIR_INTERVAL}
done