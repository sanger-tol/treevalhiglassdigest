#!/usr/bin/env python3

import os
import sys
import argparse
import csv
import requests


def parse_args(args=None):
    Description = "Parse contents of an ENA Assembly report and pul out meta data required by a genome note."
    Epilog = "Example usage: python generate_higlass_link.py <FILE_NAME> <MAP_UUID> <GRID_UUID> <GENOME_FILE>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("FILE_NAME", help="Prefix file name for the project.")
    parser.add_argument("TOLID", help="ToLID.")
    parser.add_argument("MAP_UUID", help="UUID for the .mcool file tileset.")
    parser.add_argument("GRID_UUID", help="UUID for the .genome file tileset.")
    parser.add_argument("COV_UUID", help="UUID for the _coverage.bw  file tileset.")
    parser.add_argument("REP_UUID", help="UUID for the _repeat_density.bw file tileset.")
    parser.add_argument("TELO_UUID", help="UUID for the _telo.bed file tileset.")
    parser.add_argument("GAP_UUID", help="UUID for the _gap.bed file tileset.")
    parser.add_argument("HIGLASS_SERVER", help="Higlass server url")
    parser.add_argument("GENOME_FILE", help="Input .genome file")
    parser.add_argument("OUTPUT_FILE", help="Output .csv file")
    parser.add_argument("--version", action="version", version="%(prog)s 1.0")
    return parser.parse_args(args)


def calculate_genome_size(file_in):
    # calculate total genome length by adding all contig/scaffold lengths in the .genome file
    genome_length = 0
    with open(file_in) as csvfile:
        reader = csv.reader(csvfile, delimiter="\t")
        for row in reader:
            genome_length += int(row[1])

    return genome_length


def check_viewconfig_exists(higlass_server, file_name):
    # Use HiGlass API to see if a viewconfig matching the file_name already exists on the server
    headers = {"Content-Type": "application/json"}
    params = {"d": file_name}
    response = requests.get(f"{higlass_server}/api/v1/viewconfs/l/", params=params, headers=headers)
    if response:
        return True
    return False


def request_viewconfig(higlass_server, file_name, tolid, map_uuid, grid_uuid, cov_uuid, rep_uuid, telo_uuid, gap_uuid, genome_length):
    # define viewconfig, "contents" array should contain a section for each filetype.
    # uid of viewconfig should match the file_name
    editable=True
    zoomFixed=False

    request_data = {
        "uid": file_name,
        "viewconf": {
            "editable": editable,
            "zoomFixed": zoomFixed,
            "trackSourceServers": ["/api/v1"],
            "exportViewUrl": "/api/v1/viewconfs/",
            "views": [
                {
                    "tracks": {
                        "top": [
                            {
                                "filetype": "beddb",
                                "server": f"{higlass_server}/api/v1",
                                "tilesetUid": telo_uuid,
                                "uid": "",
                                "type": "bedlike",
                                "options": {
                                "alternating": False,
                                "annotationStyle": "box",
                                "fillColor": "blue",
                                "fillOpacity": 0.3,
                                "fontSize": "10",
                                "axisPositionHorizontal": "right",
                                "labelColor": "black",
                                "labelPosition": "hidden",
                                "labelLeftMargin": 0,
                                "labelRightMargin": 0,
                                "labelTopMargin": 0,
                                "labelBottomMargin": 0,
                                "minHeight": 20,
                                "maxAnnotationHeight": None,
                                "trackBorderWidth": 0,
                                "trackBorderColor": "black",
                                "valueColumn": None,
                                "colorEncoding": "itemRgb",
                                "showTexts": False,
                                "colorRange": [
                                    "#000000",
                                    "#652537",
                                    "#bf5458",
                                    "#fba273",
                                    "#ffffe0"
                                ],
                                "colorEncodingRange": False,
                                "separatePlusMinusStrands": False,
                                "annotationHeight": 16,
                                "name": f"{tolid}_telomere"
                                },
                                "width": 20,
                                "height": 20
                            },
                            {
                                "filetype": "beddb",
                                "server": f"{higlass_server}/api/v1",
                                "tilesetUid": gap_uuid,
                                "uid": "",
                                "type": "bedlike",
                                "options": {
                                "alternating": False,
                                "annotationStyle": "box",
                                "fillColor": "blue",
                                "fillOpacity": 0.3,
                                "fontSize": "10",
                                "axisPositionHorizontal": "right",
                                "labelColor": "black",
                                "labelPosition": "hidden",
                                "labelLeftMargin": 0,
                                "labelRightMargin": 0,
                                "labelTopMargin": 0,
                                "labelBottomMargin": 0,
                                "minHeight": 20,
                                "maxAnnotationHeight": None,
                                "trackBorderWidth": 0,
                                "trackBorderColor": "black",
                                "valueColumn": None,
                                "colorEncoding": "itemRgb",
                                "showTexts": False,
                                "colorRange": [
                                    "#000000",
                                    "#652537",
                                    "#bf5458",
                                    "#fba273",
                                    "#ffffe0"
                                ],
                                "colorEncodingRange": False,
                                "separatePlusMinusStrands": True,
                                "annotationHeight": 16,
                                "name": f"{tolid}_seqgap"
                                },
                                "width": 20,
                                "height": 20
                            },
                            {
                                "filetype": "bigwig",
                                "server": f"{higlass_server}/api/v1",
                                "tilesetUid": rep_uuid,
                                "uid": "",
                                "type": "bar",
                                "options": {
                                "align": "bottom",
                                "labelColor": "[glyph-color]",
                                "labelPosition": "topLeft",
                                "labelLeftMargin": 0,
                                "labelRightMargin": 0,
                                "labelTopMargin": 0,
                                "labelBottomMargin": 0,
                                "labelShowResolution": False,
                                "labelShowAssembly": True,
                                "axisLabelFormatting": "scientific",
                                "axisPositionHorizontal": "right",
                                "barFillColor": "darkgreen",
                                "valueScaling": "linear",
                                "trackBorderWidth": 0,
                                "trackBorderColor": "black",
                                "labelTextOpacity": 0.4,
                                "barOpacity": 1,
                                "name": f"{tolid}_repeat_density"
                                },
                                "width": 20,
                                "height": 20
                            },
                            {
                                "filetype": "bigwig",
                                "server": f"{higlass_server}/api/v1",
                                "tilesetUid": cov_uuid,
                                "uid": "",
                                "type": "bar",
                                "options": {
                                "align": "bottom",
                                "labelColor": "[glyph-color]",
                                "labelPosition": "topLeft",
                                "labelLeftMargin": 0,
                                "labelRightMargin": 0,
                                "labelTopMargin": 0,
                                "labelBottomMargin": 0,
                                "labelShowResolution": False,
                                "labelShowAssembly": True,
                                "axisLabelFormatting": "scientific",
                                "axisPositionHorizontal": "right",
                                "barFillColor": "darkgreen",
                                "valueScaling": "linear",
                                "trackBorderWidth": 0,
                                "trackBorderColor": "black",
                                "labelTextOpacity": 0.4,
                                "barOpacity": 1,
                                "name": f"{tolid}_coverage"
                                },
                                "width": 20,
                                "height": 20
                            }
                        ],
                        "left": [],
                        "center": [
                            {
                                "uid": "",
                                "type": "combined",
                                "contents": [
                                    {
                                        "filetype": "cooler",
                                        "server": f"{higlass_server}/api/v1",
                                        "tilesetUid": map_uuid,
                                        "uid": "",
                                        "type": "heatmap",
                                    },
                                    {
                                        "filetype": "chromsizes-tsv",
                                        "server": f"{higlass_server}/api/v1",
                                        "tilesetUid": grid_uuid,
                                        "uid": "",
                                        "type": "2d-chromosome-grid",
                                        "options": {"lineStrokeWidth": 1, "lineStrokeColor": "grey"},
                                        "width": 20,
                                        "height": 20,
                                    },
                                ],
                                "width": 1583,
                                "height": 788,
                            }
                        ],
                        "right": [],
                        "bottom": [],
                    },
                    "initialXDomain": [0, genome_length],
                    "initialYDomain": [0, genome_length],
                    "layout": {"w": 12, "h": 12, "x": 0, "y": 0, "i": "", "moved": "false", "static": "false"},
                }
            ],
            "zoomLocks": {"locksByViewUid": {}, "locksDict": {}},
            "locationLocks": {"locksByViewUid": {}, "locksDict": {}},
            "valueScaleLocks": {"locksByViewUid": {}, "locksDict": {}},
        },
    }

    headers = {"Content-Type": "application/json"}

    response = requests.post(f"{higlass_server}/api/v1/viewconfs/", json=request_data, headers=headers)

    if response:
        viewconf_uid = response.json()["uid"]
        url = f"{higlass_server}/l/?d=" + viewconf_uid
        return url
    else:
        error_str = "ERROR: Posting view config failed"
        print(error_str)
        sys.exit(1)


def make_dir(path):
    if len(path) > 0:
        os.makedirs(path, exist_ok=True)


def print_output(url, file_out):
    out_dir = os.path.dirname(file_out)
    make_dir(out_dir)
    with open(file_out, "w") as fout:
        fout.write(",".join(["Higlass URL", url]) + "\n")


def main(args=None):
    args = parse_args(args)

    # total genome length is required when creating viewconfig
    length = calculate_genome_size(args.GENOME_FILE)

    # file name is used as the uid for the view config, it can't contain a "."
    file_name = args.FILE_NAME.replace(".", "_")

    # check if already have a viewconfig matching the file name
    exists = check_viewconfig_exists(args.HIGLASS_SERVER, file_name)
    if exists:
        # return existing viewconfig url
        url = f"{args.HIGLASS_SERVER}/l/?d={file_name}"
    else:
        # create a new viewconfig and return the url
        url = request_viewconfig(args.HIGLASS_SERVER, file_name, args.TOLID, args.MAP_UUID, args.GRID_UUID, args.COV_UUID, args.REP_UUID, args.TELO_UUID, args.GAP_UUID, length) #

    print_output(url, args.OUTPUT_FILE)


if __name__ == "__main__":
    sys.exit(main())
