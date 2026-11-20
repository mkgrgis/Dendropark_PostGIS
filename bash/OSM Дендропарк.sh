#!/bin/bash
# https://nominatim.openstreetmap.org/lookup?osm_ids=R5851116&format=json
"$(dirname "$0")/OSM Osmium import.sh" '55.5878667,37.6696677,55.6067487,37.6859570' 'Бирюлёвский дендропарк: OSM' '∀' "$1";
