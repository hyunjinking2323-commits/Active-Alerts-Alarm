//
//  Input:Output.swift
//  Check It NOW!
//
//  Created by t2025-m0239 on 2026.03.24.
//


import RxSwift

protocol ViewModelType {
    associatedtype Input
    associatedtype Output

    func transform(input: Input) -> Output
}
