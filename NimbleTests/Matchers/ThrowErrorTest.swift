import XCTest
import Nimble

enum Error : ErrorType {
    case Laugh
    case Cry
}

enum EquatableError : ErrorType {
    case Parameterized(x: Int)
}

extension EquatableError : Equatable {
}

func ==(lhs: EquatableError, rhs: EquatableError) -> Bool {
    switch (lhs, rhs) {
    case (.Parameterized(let l), .Parameterized(let r)):
        return l == r
    }
}

enum CustomDebugStringConvertibleError : ErrorType {
    case A
    case B
}

extension CustomDebugStringConvertibleError : CustomDebugStringConvertible {
    var debugDescription : String {
        return "code=\(_code)"
    }
}

class ThrowErrorTest: XCTestCase {
    
    func testPositiveMatches() {
        expect { throw Error.Laugh }.to(throwError())
        expect { throw Error.Laugh }.to(throwError(Error.Laugh))
        expect { throw EquatableError.Parameterized(x: 1) }.to(throwError(EquatableError.Parameterized(x: 1)))
        expect { throw EquatableError.Parameterized(x: 1) }.to(throwError(EquatableError.Parameterized(x: 2)))
    }

    func testPositiveMatchesWithClosures() {
        expect { throw EquatableError.Parameterized(x: 42) }.to(throwError { error in
            guard case EquatableError.Parameterized(let x) = error else { fail(); return }
            expect(x).to(equal(42))
        })
        expect { throw Error.Laugh }.to(throwError(Error.Laugh) { error in
            expect(error._domain).to(beginWith("Nim"))
        })
        expect { throw Error.Laugh }.to(throwError(Error.Laugh) { error in
            expect(error._domain).toNot(beginWith("as"))
        })
    }

    func testNegativeMatches() {
        // Different case
        failsWithErrorMessage("expected to throw error <NimbleTests.Error.Cry>, got <NimbleTests.Error.Laugh>") {
            expect { throw Error.Laugh }.to(throwError(Error.Cry))
        }
        // Different case, implementing CustomDebugStringConvertible
        failsWithErrorMessage("expected to throw error <code=1>, got <code=0>") {
            expect { throw CustomDebugStringConvertibleError.A }.to(throwError(CustomDebugStringConvertibleError.B))
        }
    }
    
    func testPositiveNegatedMatches() {
        // No error at all
        expect { return }.toNot(throwError())
        // Different case
        expect { throw Error.Laugh }.toNot(throwError(Error.Cry))
    }
    
    func testNegativeNegatedMatches() {
        // No error at all
        failsWithErrorMessage("expected to not throw any error, got <NimbleTests.Error.Laugh>") {
            expect { throw Error.Laugh }.toNot(throwError())
        }
        // Different error
        failsWithErrorMessage("expected to not throw error <NimbleTests.Error.Laugh>, got <NimbleTests.Error.Laugh>") {
            expect { throw Error.Laugh }.toNot(throwError(Error.Laugh))
        }
    }

    func testNegativeMatchesDoNotCallClosureWithoutError() {
        failsWithErrorMessage("expected to throw error that satisfies block, got no error") {
            expect { return }.to(throwError { error in
                fail()
            })
        }
        
        failsWithErrorMessage("expected to throw error <NimbleTests.Error.Laugh> that satisfies block, got no error") {
            expect { return }.to(throwError(Error.Laugh) { error in
                fail()
            })
        }
    }

    func testNegativeMatchesWithClosure() {
        let innerFailureMessage = "expected to equal <foo>, got <NimbleTests.Error>"
        let closure = { (error: ErrorType) in
            expect(error._domain).to(equal("foo"))
        }

        failsWithErrorMessage([innerFailureMessage, "expected to throw error that satisfies block, got <NimbleTests.Error.Laugh>"]) {
            expect { throw Error.Laugh }.to(throwError(closure: closure))
        }

        failsWithErrorMessage([innerFailureMessage, "expected to throw error <NimbleTests.Error.Laugh> that satisfies block, got <NimbleTests.Error.Laugh>"]) {
            expect { throw Error.Laugh }.to(throwError(Error.Laugh, closure: closure))
        }
    }
}
