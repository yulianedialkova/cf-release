package handlers_test

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"

	"github.com/cloudfoundry/routing-api/handlers"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func newTestRequest(body interface{}) *http.Request {
	var reader io.Reader
	switch body := body.(type) {

	case string:
		reader = strings.NewReader(body)
	case []byte:
		reader = bytes.NewReader(body)
	default:
		jsonBytes, err := json.Marshal(body)
		Ω(err).ShouldNot(HaveOccurred())
		reader = bytes.NewReader(jsonBytes)
	}

	request, err := http.NewRequest("", "", reader)
	Ω(err).ToNot(HaveOccurred())
	return request
}

var _ = Describe("RoutesHandler", func() {
	var (
		routesHandler    *handlers.RoutesHandler
		request          *http.Request
		responseRecorder *httptest.ResponseRecorder
	)

	BeforeEach(func() {
		routesHandler = handlers.NewRoutesHandler(50)
		responseRecorder = httptest.NewRecorder()
	})

	Describe(".Routes", func() {
		Context("POST", func() {
			var (
				routeDeclaration handlers.RouteDeclaration
			)

			BeforeEach(func() {
				routeDeclaration = handlers.RouteDeclaration{
					Route: "/post_here",
					Ttl:   50,
					Ip:    "1.2.3.4",
					Port:  7000,
				}
			})

			It("Returns an http status ok", func() {
				request = newTestRequest(routeDeclaration)
				routesHandler.Routes(responseRecorder, request)

				Expect(responseRecorder.Code).Should(Equal(http.StatusOK))
			})

			It("rejects if too high of a ttl", func() {
				routesHandler = handlers.NewRoutesHandler(47)
				request = newTestRequest(handlers.RouteDeclaration{
					Route: "/post_here",
					Ttl:   49,
					Ip:    "1.2.3.4",
					Port:  7000,
				})

				routesHandler.Routes(responseRecorder, request)

				Expect(responseRecorder.Code).Should(Equal(http.StatusBadRequest))
				Expect(string(responseRecorder.Body.String())).Should(Equal("Max ttl is 47"))
			})

			It("returns invalid request if there is no route in the body", func() {
				routeDeclaration.Route = ""

				request = newTestRequest(routeDeclaration)
				routesHandler.Routes(responseRecorder, request)

				Expect(responseRecorder.Code).Should(Equal(http.StatusBadRequest))
				Expect(string(responseRecorder.Body.String())).Should(Equal("Request requires a route"))
			})

			It("returns invalid request if the port is less than 1", func() {
				routeDeclaration.Port = 0

				request = newTestRequest(routeDeclaration)
				routesHandler.Routes(responseRecorder, request)

				Expect(responseRecorder.Code).Should(Equal(http.StatusBadRequest))
				Expect(string(responseRecorder.Body.String())).Should(Equal("Request requires a port greater than 0"))
			})

			It("returns invalid request if there is no IP in the body", func() {
				routeDeclaration.Ip = ""

				request = newTestRequest(routeDeclaration)
				routesHandler.Routes(responseRecorder, request)

				Expect(responseRecorder.Code).Should(Equal(http.StatusBadRequest))
				Expect(string(responseRecorder.Body.String())).Should(Equal("Request requires a valid ip"))
			})

			It("returns invalid request if the ttl is less than 1 in the body", func() {
				routeDeclaration.Ttl = 0

				request = newTestRequest(routeDeclaration)
				routesHandler.Routes(responseRecorder, request)

				Expect(responseRecorder.Code).Should(Equal(http.StatusBadRequest))
				Expect(string(responseRecorder.Body.String())).Should(Equal("Request requires a ttl greater than 0"))
			})
		})
	})
})
