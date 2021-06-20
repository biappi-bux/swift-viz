import SwiftSyntax
import Foundation
import ArgumentParser

typealias TypeInfoResult = Result<TypeInfos, Error>

struct Graph {
    private(set) var nodes = Set<String>()
    private(set) var edges = [String : [String]]()

    mutating func addEdge(from startNode: String, to endNode: String) {
        nodes.insert(startNode)
        nodes.insert(endNode)

        edges[startNode, default:[]].append(endNode)
    }

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
        let className = node.identifier.text

        if let clause = node.inheritanceClause {
            for type in clause.inheritedTypeCollection {
//                var toReturn = ""
//                let typename = type.typeName

//                        print("\(t.typeName.syntaxNodeType)  --  \(t.typeName.children.map { "\($0.syntaxNodeType)" }.joined(separator: " - "))")

                var childrens = type.typeName.children.makeIterator()

                let firstChild = childrens.next()
                let secondChild = childrens.next()

                guard let firstChild = firstChild else {
                    fatalError("zero children in InheritedTypeSyntax")
                }

                guard let tokenSyntax = firstChild.as(TokenSyntax.self) else {
                    fatalError("first child is not TokenSyntax")
                }

                var typeName = tokenSyntax.text

                if let secondChild = secondChild {
                    guard let argumentClause = secondChild.as(GenericArgumentClauseSyntax.self) else {
                        fatalError("second child is not GenericArgumentClauseSyntax")
                    }

                    let moreTypes = argumentClause.arguments.map {
                        $0.children.first!.withoutTrivia().description
                    }

                    let nonSpecializedTypename = typeName
                    typeName = "\(typeName)<\(moreTypes.joined(separator: ", "))>"

                    typeGraph.classesToInheritedTypes.addEdge(from: typeName, to: nonSpecializedTypename)
                    typeGraph.classesToInheritedTypes.addEdges(from: typeName, to: moreTypes)
                }

                typeGraph.classesToInheritedTypes.addEdge(from: className, to: typeName)
            }
        }
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

typealias FileProcResult = [String : TypeInfoResult]

func mergeResults(results: FileProcResult) -> Graph {
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

    return combinedGraph
}

struct GenerateHTML: ParsableCommand {
    enum Output: EnumerableFlag {
        case d3
        case vizjs

        var generator: (Graph) -> String {
            switch self {
            case .d3: return graphHTML_D3
            case .vizjs: return graphHTML_VizJS
            }
        }
    }

    @Argument(help: "Path of the directory to recursively scan")
    var path: String

    @Flag(help: "Output format to use")
    var format = Output.d3

    @Flag(name: .shortAndLong, help: "Use multithread")
    var threaded = false

    func run() throws {
        var results = FileProcResult()

        let paths = (FileManager()
            .enumerator(atPath: path)?
            .compactMap { $0 as?  String }
            .filter     { $0.hasSuffix(".swift") }
        ) ?? []

        let recursion: ParsingStrategy =
            threaded
                ? ThreadedParsing()
                : NonThreadedParsing()

        recursion.parse(
            recursivePath: path,
            paths: paths,
            parse: { (path, name) in parseSingle(filename: path) },
            collect: { (parsed, path, name) in results[name] = parsed },
            end: {
                let combinedGraph = mergeResults(results: results)
                let html = format.generator(combinedGraph)

                print(html)

                GenerateHTML.exit()
            }
        )
    }
}

GenerateHTML.main()
