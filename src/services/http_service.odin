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
	
	// Parse URL to get host and path
	url_str := request.url
	is_https := strings.has_prefix(url_str, "https://")
	if is_https {
		url_str = strings.trim_prefix(url_str, "https://")
	} else {
		url_str = strings.trim_prefix(url_str, "http://")
	}
	
	host, path, found := strings cutter(url_str, "/")
	if !found {
		host = url_str
		path = "/"
	}
	
	port := 80
	if is_https {
		port = 443
	}
	
	// Check for port in host
	host_parts := strings.split(host, ":")
	if len(host_parts) == 2 {
		host = host_parts[0]
		// Note: port parsing would go here
	}
	
	// Dial TCP connection
	addr := fmt.Sprintf("%s:%d", host, port)
	conn, err := net.dial_tcp(addr)
	if err != nil {
		log_info(svc.logger, fmt.Sprintf("Failed to connect to %s: %v", addr, err))
		return response, errors.err_network(fmt.Sprintf("Failed to connect: %v", err))
	}
	defer net.close(conn)
	
	// Build HTTP request
	method_str := "GET"
	switch request.method {
	case .GET: method_str = "GET"
	case .POST: method_str = "POST"
	case .PUT: method_str = "PUT"
	case .DELETE: method_str = "DELETE"
	case .PATCH: method_str = "PATCH"
	}
	
	request_str := fmt.sprintf("%s %s HTTP/1.1\r\n", method_str, path)
	request_str += fmt.sprintf("Host: %s\r\n", host)
	request_str += "Connection: close\r\n"
	
	if request.body != "" {
		request_str += fmt.sprintf("Content-Length: %d\r\n", len(request.body))
		request_str += "Content-Type: application/json\r\n"
	}
	
	for _, header in request.headers {
		request_str += fmt.sprintf("%s: %s\r\n", header.key, header.value)
	}
	
	request_str += "\r\n"
	
	if request.body != "" {
		request_str += request.body
	}
	
	// Send request
	_, send_err := conn.send([]byte(request_str))
	if send_err != nil {
		log_info(svc.logger, fmt.Sprintf("Failed to send request: %v", send_err))
		return response, errors.err_network(fmt.Sprintf("Failed to send request: %v", send_err))
	}
	
	// Receive response
	buf := make([]u8, 8192)
	response_body := ""
	
	for {
		n, recv_err := conn.recv(buf)
		if recv_err != nil {
			break
		}
		response_body += string(buf[:n])
		if n < len(buf) {
			break
		}
	}
	
	// Parse HTTP response
	lines := strings.split(response_body, "\r\n")
	if len(lines) < 1 {
		return response, errors.err_parse("Invalid HTTP response")
	}
	
	// Parse status line: "HTTP/1.1 200 OK"
	status_parts := strings.split(lines[0], " ")
	if len(status_parts) >= 2 {
		response.status_code = 200 // Default
		fmt.sscanf(status_parts[1], "%d", &response.status_code)
	}
	
	// Find body (after blank line)
	body_start := -1
	for i in 1..<len(lines) {
		if lines[i] == "" {
			body_start = i + 1
			break
		}
	}
	
	if body_start > 0 && body_start < len(lines) {
		response.body = strings.join(lines[body_start:], "\r\n")
	}
	
	log_info(svc.logger, fmt.Sprintf("HTTP response: %d", response.status_code))
	
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
