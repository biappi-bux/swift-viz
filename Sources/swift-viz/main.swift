import SwiftSyntax
import Foundation
import ArgumentParser

typealias TypeInfoResult = Result<TypeInfos, Error>

struct Graph {
    private(set) var nodes = Set<String>()
    private(set) var edges = [String : [String]]()

    mutating func addEdges(from startNode: String, to endNodes: [String]) {
        nodes.insert(startNode)
        nodes.formUnion(endNodes)

        edges[startNode, default:[]].append(contentsOf: endNodes)
    }

    mutating func mergeWith(_ graph: Graph) {
        for (parent, childs) in graph.edges {
            addEdges(from: parent, to: childs)
        }
    }
}

struct TypeInfos {
    var classesToInheritedTypes = Graph()
}

class Visitor : SyntaxVisitor {

    var typeGraph = TypeInfos()

    override func visitPost(_ node: ClassDeclSyntax) {
        let trimHack = { (string: String) in
            return string
                .split(separator: "\n")
                .map {
                    $0.trimmingCharacters(in: .whitespaces)
                }
                .joined(separator: " ")
        }

        let className = node.identifier.description
        let inherited = node.inheritanceClause.map { $0.inheritedTypeCollection.map { trimHack($0.description) } } ?? []

        typeGraph.classesToInheritedTypes.addEdges(
            from: trimHack(className),
            to: inherited
        )
    }
}

func parseSingle(filename: String) -> TypeInfoResult {
    do {
        let syntax = try SyntaxParser.parse(URL(fileURLWithPath: filename))

        let v = Visitor()
        v.walk(syntax)

        return .success(v.typeGraph)
    }
    catch {
        return .failure(error)
    }
}

func threadedRecurse(recursivePath: String) {
    let queue = DispatchQueue(
        label: "processing",
        qos: .userInitiated,
        attributes: .concurrent,
        autoreleaseFrequency: .inherit,
        target: .global(qos: .userInitiated)
    )

    let group = DispatchGroup()

    var results = [TypeInfoResult]()

    let addToQueue = { (name: String) in
        queue.async {
            group.enter()
            let result = parseSingle(filename: "\(recursivePath)/\(name)")

            DispatchQueue.main.async {
                group.leave()
                results.append(result)
            }
        }
    }

    FileManager()
        .enumerator(atPath: recursivePath)?
        .compactMap { $0 as?  String }
        .filter     { $0.hasSuffix(".swift") }
        .forEach    { addToQueue($0) }

    group.notify(queue: DispatchQueue.main) {
        print("ENDE")
    }
}

func generateHTML(recursivePath: String) -> String {
    let recursivePath = "/Users/willy/Sources/ios-stocks/Stocks"

    var results = [String : TypeInfoResult]()

    FileManager()
        .enumerator(atPath: recursivePath)?
        .compactMap { $0 as?  String }
        .filter     { $0.hasSuffix(".swift") }
//        .prefix(10)
        .forEach {
            results[$0] = parseSingle(filename: "\(recursivePath)/\($0)")
        }

    var combinedGraph = Graph()

    for (filename, result) in results {
        _ = filename

        switch result {
        case .success(let g):
            combinedGraph.mergeWith(g.classesToInheritedTypes)

        case .failure(let e):
            _ = e
            continue
        }
    }

    return graphHTML(graph: combinedGraph)
}

struct GenerateHTML: ParsableCommand {
    @Argument(help: "Path of the directory to recursively scan")

    var path: String

    func run() throws {
        print(generateHTML(recursivePath: path))
    }
}

GenerateHTML.main()
