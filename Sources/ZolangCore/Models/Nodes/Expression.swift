//
//  Expression.swift
//  Zolang
//
//  Created by Þorvaldur Rúnarsson on 28/06/2018.
//

import Foundation

public indirect enum Expression: Node {
    case integerLiteral(String)
    case floatLiteral(String)
    case stringLiteral(String)
    case identifier(String)
    case listAccess(String, Expression)
    case listLiteral([Expression])
    case functionCall(String, [Expression])
    case parentheses(Expression)
    case operation(Expression, String, Expression)
    
    public init(tokens: [Token], context: inout ParserContext) throws {
        var tokens = tokens
        
        context.line += tokens.trimLeadingNewlines()

        let validValuePrefix: [(key: ValueType, value: [TokenType])] = [
            (.parentheses, [ .parensOpen ]),
            (.listLiteral, [ .bracketOpen ]),
            (.functionCall, [ .identifier, .parensOpen ]),
            (.listAccess, [ .identifier, .bracketOpen ]),
            (.identifier, [ .identifier ]),
            (.integerLiteral, [ .decimal ]),
            (.floatLiteral, [ .floatingPoint ]),
            (.stringLiteral, [ .stringLiteral ])
        ]
        
        guard let valueType = (validValuePrefix.first { (key, types) -> Bool in
            tokens.hasPrefixTypes(types: types, skipping: [ .newline ])
        })?.key else {
            throw ZolangError(type: .invalidExpression, file: context.file, line: context.line)
        }
        
        switch valueType {
        case .listAccess:
            let lineCount = tokens.newLineCount(to: tokens.index(ofNextWithTypeIn: [ .bracketOpen ])!)
            guard let range = tokens.rangeOfScope(open: .bracketOpen, close: .bracketClose) else {
    
                throw ZolangError(type: .missingMatchingBracket, file: context.file, line: context.line + lineCount)
            }

            
            if let operatorExpression = try Expression.parseOperator(index: range.upperBound + 1,
                                                                     tokens: tokens,
                                                                     context: &context) {
                self = operatorExpression
                
            } else {
                guard let identifier = tokens.first(where: { $0.type == .identifier })?.payload else {
                    throw ZolangError(type: .missingIdentifier, file: context.file, line: context.line)
                }

                guard let innerTokenRange = tokens.rangeOfScope(open: .bracketOpen, close: .bracketClose),
                    innerTokenRange.count >= 3 else {
                    throw ZolangError(type: .invalidExpression, file: context.file, line: context.line)
                }
                
                let innerTokens = Array(tokens[innerTokenRange.lowerBound+1..<innerTokenRange.upperBound])
            
                guard innerTokens.isEmpty == false else {
                    throw ZolangError(type: .invalidExpression, file: context.file, line: context.line)
                }

                self = .listAccess(identifier, try Expression(tokens: innerTokens, context: &context))
            }
        case .parentheses:
            guard let parensRange = tokens.rangeOfScope(open: .parensOpen, close: .parensClose) else {
                throw ZolangError(type: .missingMatchingParens, file: context.file, line: context.line)
            }
            
            guard parensRange.count > 2 else {
                throw ZolangError(type: .invalidExpression, file: context.file, line: context.line)
            }
            
            if let operatorExpression = try Expression.parseOperator(index: parensRange.upperBound + 1,
                                                                     tokens: tokens,
                                                                     context: &context) {
                self = operatorExpression
                
            } else {
                let innerTokenRange: CountableRange<Int> = (parensRange.lowerBound + 1)..<parensRange.upperBound
                let innerTokens = Array(tokens[innerTokenRange])
                
                self = .parentheses(try Expression(tokens: innerTokens, context: &context))
            }
        case .functionCall:
            throw ZolangError.ErrorType.unknown
        case .listLiteral:
            throw ZolangError.ErrorType.unknown
        case .identifier:
            if let operatorExpression = try Expression.parseOperator(index: 1,
                                                                     tokens: tokens,
                                                                     context: &context) {
                self = operatorExpression
                
            } else {
                guard tokens.count == 1 else {
                    throw ZolangError(type: .unexpectedToken(tokens[1], nil),
                                      file: context.file,
                                      line: context.line)
                }
                
                self = .identifier(tokens.first!.payload!)
            }
        case .floatLiteral:
            if let operatorExpression = try Expression.parseOperator(index: 1,
                                                                     tokens: tokens,
                                                                     context: &context) {
                self = operatorExpression
                
            } else {
                guard tokens.count == 1 else {
                    throw ZolangError(type: .unexpectedToken(tokens[1], nil),
                                      file: context.file,
                                      line: context.line)
                }

                self = .floatLiteral(tokens.first!.payload!)
            }
        case .integerLiteral:
            if let operatorExpression = try Expression.parseOperator(index: 1,
                                                                     tokens: tokens,
                                                                     context: &context) {
                self = operatorExpression
                
            } else {
                guard tokens.count == 1 else {
                    throw ZolangError(type: .unexpectedToken(tokens[1], nil),
                                      file: context.file,
                                      line: context.line)
                }
                
                self = .integerLiteral(tokens.first!.payload!)
            }
        case .stringLiteral:
            if let operatorExpression = try Expression.parseOperator(index: 1,
                                                                     tokens: tokens,
                                                                     context: &context) {
                self = operatorExpression
                
            } else {
                guard tokens.count == 1 else {
                    throw ZolangError(type: .unexpectedToken(tokens[1], nil),
                                      file: context.file,
                                      line: context.line)
                }
                
                self = .stringLiteral(tokens.first!.payload!)
            }
        }
    }
    
    static func parseOperator(index: Int, tokens: [Token], context: inout ParserContext) throws -> Expression? {
        var tokens = tokens

        guard index < tokens.count,
            let nextIndex = tokens.index(ofFirstThatIsNot: .newline, startingAt: index),
            nextIndex != tokens.count - 1,
            tokens[nextIndex].type == .operator else {
            return nil
        }
        
        let newlinesToAdd = tokens.trimNewlines(to: nextIndex)
        let to = nextIndex - newlinesToAdd

        let leftTokens = Array(tokens[..<to])
        let rightTokens = Array(tokens[to+1..<tokens.count])
        
        var leftExpressionTokens = leftTokens
        leftExpressionTokens.trimTrailingNewlines()

        let firstExpression = try Expression(tokens: leftExpressionTokens, context: &context)
        
        context.line += newlinesToAdd
        
        let secondExpression = try Expression(tokens: rightTokens, context: &context)
        
        return .operation(firstExpression,
                          tokens[nextIndex].payload!,
                          secondExpression)
    }
}

extension Expression {
    private enum ValueType: String {
        case functionCall
        case parentheses
        case listAccess
        case listLiteral
        case identifier
        case integerLiteral
        case floatLiteral
        case stringLiteral
    }
}
