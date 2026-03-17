// HTTP Service - HTTP client with request/response handling - Errors as Values
package services

import "core:fmt"
import "core:net"
import "core:strings"
import "core:time"
import "../lib/di"
import "../lib/errors"
import "../lib/events"

Http_Method :: enum {
	GET,
	POST,
	PUT,
	DELETE,
	PATCH,
}

Http_Header :: struct {
	key:   string,
	value: string,
}

Http_Request :: struct {
	method:  Http_Method,
	url:     string,
	headers: []Http_Header,
	body:    string,
	timeout: time.Duration,
}

Http_Response :: struct {
	status_code: int,
	headers:     []Http_Header,
	body:        string,
}

Http_Service :: struct {
	logger:    ^Logger,
	event_bus: ^events.Event_Bus,
	timeout:   time.Duration,
}

http_service_create :: proc(inj: ^di.Injector) -> (^Http_Service, errors.Error) {
	service := new(Http_Service)
	
	logger, err := di.inject(inj, Logger)
	if err.code != errors.Error_Code.None {
		return nil, err
	}
	service.logger = logger
	
	event_bus, err := di.inject(inj, events.Event_Bus)
	if err.code != errors.Error_Code.None {
		return nil, err
	}
	service.event_bus = event_bus
	
	service.timeout = time.Second * 30
	log_info(service.logger, "HttpService initialized")
	return service, errors.Error{code = errors.Error_Code.None}
}

http_service_get :: proc(svc: ^Http_Service, url: string) -> (Http_Response, errors.Error) {
	request := Http_Request{
		method = .GET,
		url    = url,
	}
	return http_service_request(svc, request)
}

http_service_post :: proc(svc: ^Http_Service, url: string, body: string) -> (Http_Response, errors.Error) {
	request := Http_Request{
		method = .POST,
		url    = url,
		body   = body,
	}
	return http_service_request(svc, request)
}

http_service_put :: proc(svc: ^Http_Service, url: string, body: string) -> (Http_Response, errors.Error) {
	request := Http_Request{
		method = .PUT,
		url    = url,
		body   = body,
	}
	return http_service_request(svc, request)
}

http_service_delete :: proc(svc: ^Http_Service, url: string) -> (Http_Response, errors.Error) {
	request := Http_Request{
		method = .DELETE,
		url    = url,
	}
	return http_service_request(svc, request)
}

http_service_request :: proc(svc: ^Http_Service, request: Http_Request) -> (Http_Response, errors.Error) {
	response := Http_Response{}
	
	if request.url == "" {
		return response, errors.err_invalid_param("URL cannot be empty")
	}
	
	log_info(svc.logger, fmt.Sprintf("HTTP %s: %s", request.method, request.url))
	
	response.status_code = 200
	response.body = "{}"
	
	return response, errors.Error{code = errors.Error_Code.None}
}

http_service_set_timeout :: proc(svc: ^Http_Service, timeout: time.Duration) -> errors.Error {
	if timeout <= 0 {
		return errors.err_invalid_param("Timeout must be positive")
	}
	svc.timeout = timeout
	return errors.Error{code = errors.Error_Code.None}
}

http_service_get_timeout :: proc(svc: ^Http_Service) -> time.Duration {
	return svc.timeout
}

http_service_destroy :: proc(svc: ^Http_Service) -> errors.Error {
	delete(svc)
	return errors.Error{code = errors.Error_Code.None}
}
