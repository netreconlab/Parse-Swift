//
//  MockURLProtocol.swift
//  ParseSwiftTests
//
//  Created by Corey E. Baker on 7/19/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

typealias MockURLProtocolRequestTestClosure = (URLRequest) -> Bool
typealias MockURLResponseContructingClosure = (URLRequest) -> MockURLResponse?

struct MockURLProtocolMock: Sendable {
    var attempts: Int
    var test: @Sendable (URLRequest) -> Bool
    var response: @Sendable (URLRequest) -> MockURLResponse?
}

class MockURLProtocol: URLProtocol, @unchecked Sendable {
    var mock: MockURLProtocolMock?
	nonisolated(unsafe) static var mocks: [MockURLProtocolMock] = []
    private var loading: Bool = false
    var isLoading: Bool {
        return loading
    }

    class func mockRequests(
		response: @escaping @Sendable (URLRequest) -> MockURLResponse?
	) {
        mockRequestsPassing(Int.max, test: { _ in return true }, with: response)
    }

    class func mockRequestsPassing(
		_ test: @escaping @Sendable (URLRequest) -> Bool,
		with response: @escaping @Sendable (URLRequest) -> MockURLResponse?
	) {
        mockRequestsPassing(Int.max, test: test, with: response)
    }

    class func mockRequestsPassing(
		_ attempts: Int,
		test: @escaping @Sendable (URLRequest) -> Bool,
		with response: @escaping @Sendable (URLRequest) -> MockURLResponse?
	) {
        let mock = MockURLProtocolMock(
			attempts: attempts,
			test: test,
			response: response
		)
        mocks.append(mock)
        if mocks.count == 1 {
            URLProtocol.registerClass(MockURLProtocol.self)
        }
    }

    class func removeAll() {
        if !mocks.isEmpty {
            URLProtocol.unregisterClass(MockURLProtocol.self)
        }
        mocks.removeAll()
    }

    class func firstMockForRequest(
		_ request: URLRequest
	) -> MockURLProtocolMock? {
        for mock in mocks {
            if (mock.attempts > 0) && mock.test(request) {
                return mock
            }
        }
        return nil
    }

    override class func canInit(
		with request: URLRequest
	) -> Bool {
        MockURLProtocol.firstMockForRequest(request) != nil
    }

    override class func canInit(
		with task: URLSessionTask
	) -> Bool {
        guard let originalRequest = task.originalRequest else {
            return false
        }
        return MockURLProtocol.firstMockForRequest(originalRequest) != nil
    }

    override class func canonicalRequest(
		for request: URLRequest
	) -> URLRequest {
        request
    }

    override required init(
		request: URLRequest,
		cachedResponse: CachedURLResponse?,
		client: URLProtocolClient?
	) {
        super.init(
			request: request,
			cachedResponse: cachedResponse,
			client: client
		)
        guard let mock = MockURLProtocol.firstMockForRequest(request) else {
            self.mock = nil
            return
        }
        self.mock = mock
    }

    override func startLoading() {
        self.loading = true
        self.mock?.attempts -= 1
        guard let response = self.mock?.response(request) else {
            return
        }

        if let error = response.error {
            DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + response.delay) { [weak self] in
				guard let self else { return }
                if self.loading {
                    self.client?.urlProtocol(self, didFailWithError: error)
                }
            }
            return
        }

        guard let url = request.url,
            let urlResponse = HTTPURLResponse(
				url: url,
				statusCode: response.statusCode,
				httpVersion: "HTTP/2",
				headerFields: response.headerFields
			) else {
                return
            }

        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + response.delay) { [weak self] in
			guard let self else { return }
            if !self.loading {
                return
            }
            self.client?.urlProtocol(
				self,
				didReceive: urlResponse,
				cacheStoragePolicy: .notAllowed
			)
            if let data = response.responseData {
                self.client?.urlProtocol(self, didLoad: data)
            }
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {
        self.loading = false
    }
}
