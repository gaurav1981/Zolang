//
//  CodeBlockTests.swift
//  ZolangTests
//
//  Created by Þorvaldur Rúnarsson on 25/08/2018.
//

import XCTest
import ZolangCore

class CodeBlockTests: XCTestCase {
    
    let declarationExpressionMutation = """
    let some be "text"
    println(some)
    make some.property be "something else"
    print(some)
    """
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFailure() {
        
        let invalidCode = "make some as bla"
        let invalidSamples: [(String, Int)] = [
            ("let some be \"test\" \n\n\(invalidCode)", 2),
            ("make some be \n\"test\" \n\n\(invalidCode)", 3)
        ]
        
        for codeLineTuple in invalidSamples {
            var context = ParserContext(file: "test.zolang")

            let (code, line) = codeLineTuple
            let tokenList = Lexer().tokenize(string: code)

            do {
                _ = try CodeBlock(tokens: tokenList, context: &context)
                XCTFail("Mutation should fail - \(tokenList)")
            } catch {
                XCTAssert((error as? ZolangError)?.line == line, "\((error as? ZolangError)!.line) - \(line)")
            }
        }
    }
    
    func testDeclarationExpressionMutation() {
        var context = ParserContext(file: "test.zolang")
        
        let tokens = Lexer().tokenize(string: declarationExpressionMutation)
        do {
            let codeBlock = try CodeBlock(tokens: tokens,
                                          context: &context)
            
            guard case let .combination(firstL, firstR) = codeBlock else {
                XCTFail()
                return
            }

            guard case let .variableDeclaration(decl) = firstL else {
                XCTFail()
                return
            }
            
            XCTAssert(decl.identifier == "some")
            
            guard case let .stringLiteral(lit) = decl.expression else {
                XCTFail()
                return
            }
            
            XCTAssert(lit == "text")
            
            guard case let .combination(secondL, secondR) = firstR else {
                XCTFail()
                return
            }
            
            guard case let .expression(expr) = secondL else {
                XCTFail()
                return
            }
            
            guard case let .functionCall(call) = expr else {
                XCTFail()
                return
            }
            
            let (identifier, params) = call
            
            XCTAssert(identifier == "println")
            XCTAssert(params.count == 1)
            guard case let .identifier(funcIdentifier) = params[0] else {
                XCTFail()
                return
            }
            XCTAssert(funcIdentifier == "some")
            
            guard case let .combination(thirdL, thirdR) = secondR else {
                XCTFail()
                return
            }
            
            guard case let .variableMutation(mut) = thirdL else {
                XCTFail()
                return
            }
            
            XCTAssert(mut.identifiers == ["some", "property"])
            
            guard case let .stringLiteral(literal) = mut.expression else {
                XCTFail()
                return
            }
            
            XCTAssert(literal == "something else")
            
            guard case let .expression(lastExpr) = thirdR else {
                XCTFail()
                return
            }
            
            guard case let .functionCall(call2) = lastExpr else {
                XCTFail()
                return
            }
            
            let (identifier2, params2) = call2
            
            XCTAssert(identifier2 == "print")
            XCTAssert(params2.count == 1)
            
            guard case let .identifier(funcIdentifier2) = params2[0] else {
                XCTFail()
                return
            }
            XCTAssert(funcIdentifier2 == "some")
        } catch {
            XCTFail()
        }
    }
}
