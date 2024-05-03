#!/usr/bin/env bash

pod_name=$1
tolid=$2

# Check to see if a tileset with the same name already exists and delete it if so
tilesets=$(kubectl exec $pod_name -- python /home/higlass/projects/higlass-server/manage.py list_tilesets | (grep ${tolid} || [ "$?" == "1" ] ) | awk '{print substr($NF, 1, length($NF)-1)}')

for f in $tilesets; do
    echo "Deleting $f"
    kubectl exec $pod_name --  python /home/higlass/projects/higlass-server/manage.py delete_tileset --uuid $f
done

# Upload the file
echo "Loading ${tolid}"
kubectl exec $pod_name --  perl /home/higlass/ingest_autorun/ingest_autorun.pl $tolid
