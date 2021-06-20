//
//  ParsingStrategies.swift
//  swift-viz
//
//  Created by Antonio Malara on 20/06/2021.
//

import Foundation

protocol ParsingStrategy {
    init()

    func parse<T>(
        recursivePath: String,
        paths: [String],
        parse: @escaping (_ fullpath: String, _ filename: String) -> T,
        collect: @escaping (_ thing: T, _ fullpath: String, _ filename: String) -> Void,
        end: @escaping () -> Void
    )
}

struct NonThreadedParsing: ParsingStrategy {
    func parse<T>(
        recursivePath: String,
        paths: [String],
        parse: @escaping (_ fullpath: String, _ filename: String) -> T,
        collect: @escaping (_ thing: T, _ fullpath: String, _ filename: String) -> Void,
        end: @escaping () -> Void
    ) {
        paths
            .forEach {
                let name = $0
                let fullpath = "\(recursivePath)/\(name)"
                let parsed = parse(fullpath, name)
                collect(parsed, fullpath, name)
            }

        end()
    }
}

struct ThreadedParsing: ParsingStrategy {
    func parse<T>(
        recursivePath: String,
        paths: [String],
        parse: @escaping (_ fullpath: String, _ filename: String) -> T,
        collect: @escaping (_ thing: T, _ fullpath: String, _ filename: String) -> Void,
        end: @escaping () -> Void
    ) {
        let queue = DispatchQueue(
            label: "processing",
            qos: .userInitiated,
            attributes: .concurrent,
            autoreleaseFrequency: .inherit,
            target: .global(qos: .userInitiated)
        )

        let group = DispatchGroup()

        let addToQueue = { (name: String) in
            queue.async {
                group.enter()
                let fullpath = "\(recursivePath)/\(name)"
                let parsed = parse(fullpath, name)

                DispatchQueue.main.async {
                    group.leave()
                    collect(parsed, fullpath, name)
                }
            }
        }

        paths.forEach {
            addToQueue($0)
        }

        group.notify(queue: DispatchQueue.main) {
            end()
        }

        dispatchMain()
    }
}
