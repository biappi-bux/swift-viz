//
//  Html.swift
//  SwiftViz
//
//  Created by Antonio Malara on 18/06/2021.
//

import Foundation

func split(s: String) -> [String] {
    var result = [String]()
    var temp = s
    var done = false
    while !done {
        if let index = temp.lastIndex(where: { $0.isUppercase }) {
            result.insert(String(temp[index...]), at: 0)
            temp = String(temp[..<index])
            done = temp.distance(from: temp.startIndex, to: index) == 0
        }
        else {
            result.insert(temp, at: 0)
            done = true
        }
    }

    return result
}

let label = { (string: String) -> String in
    split(s: string).joined(separator: "\\n")
}

func graphHTML_D3(graph: Graph) -> String {
    var nodes = [String]()
    var nodeToIndex = [String : Int]()

    for (i, node) in graph.nodes.enumerated() {
        nodeToIndex[node] = i
        nodes.append("        { id: '\(node)' },")
    }

    let links = graph.edges.flatMap {
        (parent, childs) in

        childs.map {
            child in

            "        { source: '\(parent)', target: '\(child)' },"
        }
    }

    return """
        var the_data = {

            nodes: [
        \(nodes.joined(separator: "\n"))
            ],

            links: [
        \(links.joined(separator: "\n"))
            ],

        }
        """
}

func graphHTML_VizJS(graph: Graph) -> String {
    let nodesHTML =
        graph
            .nodes
            .map { "        { id: '\($0)', label: '\(label($0))' },\n" }
            .joined()

    let edgesHTML =
        graph
            .edges
            .flatMap { (parent, childs) in
                childs.map { child in
                    "        { from: '\(parent)', to: '\(child)' },\n"
                }
            }
            .joined()

    return mainHTML(
        nodesHTML: nodesHTML,
        edgesHTML: edgesHTML
    )
}

func mainHTML(nodesHTML: String, edgesHTML: String) -> String {
    return """
<html>
<head>
    <script type="text/javascript" src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>

    <style type="text/css">
        #mynetwork {
            width: 100%;
            height: 100%;
            border: 1px solid lightgray;
        }
    </style>
</head>
<body>
<div id="mynetwork"></div>

<script type="text/javascript">
    // create an array with nodes
    var nodes = new vis.DataSet([
\(nodesHTML)
    ]);

    // create an array with edges
    var edges = new vis.DataSet([
\(edgesHTML)
    ]);

    // create a network
    var container = document.getElementById('mynetwork');

    // provide the data in the vis format
    var data = {
        nodes: nodes,
        edges: edges
    };

    var options = {
/*
        layout: {
            hierarchical: {
                direction: "UD",
                sortMethod: "directed",
            },
        },
        physics: {
            hierarchicalRepulsion: {
                avoidOverlap: 1,
            },
        },
        edges: {
            smooth: true,
            arrows: { from: true },
        },
*/

         physics: {
             hierarchicalRepulsion: {
                 avoidOverlap: 1,
             },
             solver: "repulsion",
             repulsion: {
                 nodeDistance: 400,
             }
         },
         edges: {
             smooth: true,
             arrows: { from: true },
             length: 400,
         },
    };

    // initialize your network!
    var network = new vis.Network(container, data, options);
</script>
</body>
</html>
"""
}

