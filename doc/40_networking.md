## 4. Networking

### 4.1 Overview

libcoro offers comprehensive support for asynchronous networking operations in modern C++, leveraging the power of coroutines for efficient and readable code. The `coro::net` namespace houses the essential components for building network applications, enabling seamless integration of network I/O with other coroutine-based tasks.

At the core of libcoro's networking lies the `coro::net::socket` class, which provides a platform-independent abstraction for network sockets. This class encapsulates the underlying file descriptor and exposes methods for interacting with the socket, including:

- **Setting blocking mode:** Determine whether I/O operations should block or return immediately if data is not readily available (`blocking()`).
- **Socket shutdown:** Gracefully shut down the socket for reading, writing, or both (`shutdown()`).
- **Socket closure:** Close the underlying file descriptor (`close()`).

libcoro supports various network domains, represented by the `coro::net::domain_t` enum. This allows you to choose the appropriate domain for your application, such as:

- **IPv4:** `coro::net::domain_t::ipv4`
- **IPv6:** `coro::net::domain_t::ipv6`

By utilizing coroutines and executors, libcoro enables asynchronous I/O operations on sockets. You can:

- **Poll for events:** Efficiently wait for specific events on a socket, such as readability or writability, using the `poll()` method of `coro::io_scheduler`.
- **Send data:** Asynchronously send data over the network using protocol-specific methods like `send()` in `coro::net::tcp::client` and `sendto()` in `coro::net::udp::peer`.
- **Receive data:** Asynchronously receive data from the network using methods like `recv()` in `coro::net::tcp::client` and `recvfrom()` in `coro::net::udp::peer`.

These asynchronous operations allow your coroutines to suspend while waiting for network events, enabling other tasks to execute concurrently and maximizing resource utilization. This results in more responsive and scalable network applications.

Subsequent sections will delve deeper into specific networking protocols like TCP and UDP, demonstrating how to build robust client and server applications using libcoro's powerful asynchronous networking capabilities.


### 4.2 TCP

libcoro provides dedicated components within the `coro::net::tcp` namespace for building asynchronous TCP client and server applications. These components leverage the power of coroutines to offer a streamlined and efficient approach to handling TCP communication.

#### 4.2.1 `coro::net::tcp::server`

The `coro::net::tcp::server` class represents a TCP server capable of accepting incoming connections. It is designed to work seamlessly with a `coro::io_scheduler` to handle connection events asynchronously. 

**Key features:**

- **Constructor:**
    - Takes a `coro::io_scheduler` instance to manage network events.
    - Optionally accepts an `options` structure for configuring:
        - Binding address (`address`).
        - Port number (`port`).
        - Backlog size for pending connections (`backlog`).
- **`poll()`:** Awaits a new connection event, suspending the coroutine until a client attempts to connect. Returns a `coro::poll_status` indicating the result of the operation.
- **`accept()`:** Accepts an incoming connection, creating a `coro::net::tcp::client` instance representing the established connection with the client.

**Example usage:**

```cpp
auto make_server_task = [](std::shared_ptr<coro::io_scheduler> scheduler) -> coro::task<void> {
    co_await scheduler->schedule();
    coro::net::tcp::server server{scheduler, 
                                    coro::net::tcp::server::options{.port = 8080}};

    while (true) {
        // Wait for a connection event.
        auto pstatus = co_await server.poll();
        if (pstatus == coro::poll_status::event) {
            auto client = server.accept();
            // Handle the client connection.
            // ...
        } 
        // Handle other poll status...
    }
    co_return;
};
```

#### 4.2.2 `coro::net::tcp::client`

The `coro::net::tcp::client` class represents a TCP client that can connect to a server and exchange data. It utilizes the `coro::io_scheduler` for asynchronous I/O operations.

**Key features:**

- **Constructor:** 
    - Requires a `coro::io_scheduler` instance for managing network events.
    - Optionally accepts an `options` structure to configure:
        - Target server address (`address`).
        - Port number (`port`).
- **`connect()`:** Asynchronously connects to the specified server. Returns a `coro::net::connect_status` indicating the outcome of the connection attempt.
- **`poll()`:**  Awaits a specific I/O event (read, write, or both), suspending the coroutine until the event occurs. Takes a `coro::poll_op` to specify the desired event and an optional timeout. Returns a `coro::poll_status` indicating the result of the polling operation.
- **`send()`:** Asynchronously sends data to the server. Takes a `std::span<const char>` containing the data to send and an optional timeout. Returns a pair containing a `coro::net::send_status` and a `std::span<const char>` representing any remaining data that couldn't be sent immediately.
- **`recv()`:** Asynchronously receives data from the server. Takes a `std::span<char>` to store the received data and an optional timeout. Returns a pair containing a `coro::net::recv_status` and a `std::span<char>` representing the received data.

**Example usage:**

```cpp
auto make_client_task = [](std::shared_ptr<coro::io_scheduler> scheduler) -> coro::task<void> {
    co_await scheduler->schedule();
    coro::net::tcp::client client{scheduler,
                                    coro::net::tcp::client::options{
                                        .address = coro::net::ip_address::from_string("127.0.0.1"),
                                        .port = 8080
                                    }};

    auto connect_status = co_await client.connect();
    if (connect_status == coro::net::connect_status::connected) {
        // Send a message.
        auto [send_status, remaining] = co_await client.send("Hello, server!");
        // Receive a response.
        std::string response(256, '\0');
        auto [recv_status, recv_bytes] = co_await client.recv(response);
        // ...
    }
    co_return;
};
```

These TCP components, combined with libcoro's other features, provide a powerful foundation for building diverse and efficient asynchronous TCP-based applications in C++.


### 4.3 UDP

libcoro facilitates asynchronous UDP communication through the `coro::net::udp::peer` class. This class allows building UDP-based applications that leverage the advantages of coroutines for non-blocking I/O operations.

#### 4.3.1 `coro::net::udp::peer`

The `coro::net::udp::peer` class encapsulates a UDP socket and provides methods for sending and receiving datagrams. It seamlessly integrates with a `coro::io_scheduler` for asynchronous event handling.

**Key features:**

- **Constructors:**
    - Accepts a `coro::io_scheduler` instance for managing network events.
    - Offers two constructor overloads:
        - One taking a `coro::net::domain_t` to specify the desired network domain (IPv4 or IPv6). This constructor creates an unbound socket, allowing you to send datagrams to any destination.
        - Another taking a `coro::net::udp::peer::info` structure, which specifies both the network domain and the address/port for binding the socket. This allows receiving datagrams from specific sources.
- **`poll()`:**  Awaits a specific I/O event (read or write), suspending the coroutine until the event occurs. Takes a `coro::poll_op` to specify the desired event and an optional timeout. Returns a `coro::poll_status` indicating the result of the polling operation.
- **`sendto()`:** Asynchronously sends a datagram to a specific peer. Takes a `coro::net::udp::peer::info` structure identifying the destination peer, a `std::span<const char>` containing the data to send, and an optional timeout. Returns a pair containing a `coro::net::send_status` and a `std::span<const char>` representing any remaining data that couldn't be sent immediately.
- **`recvfrom()`:** Asynchronously receives a datagram from a peer. Takes a `std::span<char>` to store the received data and an optional timeout. Returns a tuple containing a `coro::net::recv_status`, a `coro::net::udp::peer::info` structure identifying the sending peer, and a `std::span<char>` representing the received data.
- **`is_bound()`:** Indicates whether the socket is bound to a specific address and port.

**Example usage:**

```cpp
auto make_receiver_task = [](std::shared_ptr<coro::io_scheduler> scheduler) -> coro::task<void> {
    co_await scheduler->schedule();
    coro::net::udp::peer::info bind_info{
        .address = coro::net::ip_address::from_string("0.0.0.0"),
        .port = 9999
    };
    coro::net::udp::peer receiver{scheduler, bind_info};

    while (true) {
        auto pstatus = co_await receiver.poll(coro::poll_op::read);
        if (pstatus == coro::poll_status::event) {
            std::string buffer(256, '\0');
            auto [rstatus, sender_info, data] = receiver.recvfrom(buffer);
            // Handle the received datagram.
            // ...
        } 
        // Handle other poll status...
    }
    co_return;
};

auto make_sender_task = [](std::shared_ptr<coro::io_scheduler> scheduler) -> coro::task<void> {
    co_await scheduler->schedule();
    coro::net::udp::peer sender{scheduler, coro::net::domain_t::ipv4};
    coro::net::udp::peer::info receiver_info{
        .address = coro::net::ip_address::from_string("127.0.0.1"),
        .port = 9999
    };

    auto [send_status, remaining] = co_await sender.sendto(receiver_info, "Hello from sender!");
    // ...
    co_return;
};
```

The `coro::net::udp::peer` class, along with libcoro's asynchronous capabilities, offers a powerful framework for creating responsive and efficient UDP applications in C++.



### 4.4 TLS/SSL (optional)

libcoro provides optional support for secure communication over TCP using TLS/SSL, available by enabling the `LIBCORO_FEATURE_TLS` compile-time feature. This functionality resides within the `coro::net::tls` namespace and revolves around the `coro::net::tls::context` class.

#### 4.4.1 `coro::net::tls::context`

The `coro::net::tls::context` class encapsulates an OpenSSL context, representing the configuration for a TLS/SSL connection. It allows you to load certificates, private keys, and set various security options.

**Key features:**

- **Constructors:**
    - Takes a `verify_peer_t` enum value to control peer certificate verification (defaults to `verify_peer_t::no`).
    - Alternatively, a constructor accepting paths to certificate and private key files, along with their file types (PEM or DER), is available for server-side configurations. This constructor also takes the `verify_peer_t` parameter.
- **`native_handle()`:** Returns the underlying `SSL_CTX` pointer, which can be used for advanced OpenSSL operations if needed.

**Example usage:**

```cpp
// Client-side context with peer verification disabled.
auto client_ctx = std::make_shared<coro::net::tls::context>(coro::net::tls::verify_peer_t::no);

// Server-side context loading certificate and private key.
auto server_ctx = std::make_shared<coro::net::tls::context>("cert.pem", coro::net::tls::tls_file_type::pem,
                                                          "key.pem", coro::net::tls::tls_file_type::pem);
```

#### 4.4.2 `coro::net::tls::server`

The `coro::net::tls::server` class builds upon the `coro::net::tcp::server` to provide a TLS/SSL-enabled TCP server. It requires a `coro::net::tls::context` for configuring the secure connection.

**Key features:**

- **Constructor:**
    - Takes a `coro::io_scheduler` instance to manage network events.
    - Requires a `coro::net::tls::context` for TLS/SSL configuration.
    - Accepts an `options` structure similar to `coro::net::tcp::server` to configure binding address, port, and backlog.
- **`poll()`:** Inherits from `coro::net::tcp::server` and behaves the same, awaiting a new connection event.
- **`accept()`:** Accepts an incoming TLS/SSL connection. It performs the TLS/SSL handshake and returns a `coro::net::tls::client` representing the secured connection.

#### 4.4.3 `coro::net::tls::client`

The `coro::net::tls::client` class extends the `coro::net::tcp::client` to enable secure communication with TLS/SSL servers. It requires a `coro::net::tls::context` to establish a secure connection.

**Key features:**

- **Constructors:**
    - Similar to `coro::net::tcp::client`, it takes a `coro::io_scheduler` and a `coro::net::tls::context`.
    - Provides an additional constructor that accepts an existing `coro::net::socket` for accepting connections from a `coro::net::tls::server`.
- **`connect()`:** Establishes a secure connection to a TLS/SSL server, performing the necessary handshake. Returns a `coro::net::tls::connection_status` indicating the outcome.
- **`poll()`, `send()`, `recv()`:** Inherit from `coro::net::tcp::client` and operate over the secured connection.

**Example usage:**

```cpp
// Server task
auto make_tls_server_task = [&]() -> coro::task<void> {
    co_await scheduler->schedule();
    coro::net::tls::server server{scheduler, server_ctx, 
                                    coro::net::tls::server::options{.port = 8443}};
    // ... accept connections and handle them ...
};

// Client task
auto make_tls_client_task = [&]() -> coro::task<void> {
    co_await scheduler->schedule();
    coro::net::tls::client client{scheduler, client_ctx,
                                    coro::net::tls::client::options{
                                        .address = coro::net::ip_address::from_string("127.0.0.1"),
                                        .port = 8443
                                    }};
    auto status = co_await client.connect();
    if (status == coro::net::tls::connection_status::connected) {
        // ... communicate securely ...
    }
};
```

libcoro's TLS/SSL support, combined with its asynchronous capabilities, empowers you to build secure and efficient network applications in C++.


### 4.5 DNS Resolution

Libcoro provides asynchronous DNS resolution capabilities through the `coro::net::dns::resolver` class. This class allows resolving hostnames to IP addresses without blocking the execution of your coroutines.

#### 4.5.1 `coro::net::dns::resolver<Executor>`

The `coro::net::dns::resolver` class is a template class that requires an executor type to be specified. The executor will handle the execution of the DNS resolution task. This allows for flexibility in choosing the execution context for DNS resolution, such as a thread pool or an I/O scheduler.

**Key features:**

- **Constructor:** 
    - Requires a shared pointer to an executor instance (e.g., `coro::thread_pool` or `coro::io_scheduler`).
    - Optionally accepts a timeout value for the DNS resolution operation (defaults to 5 seconds).
- **`host_by_name()`:** Initiates an asynchronous DNS resolution for the provided hostname. Returns a `coro::task` that yields a `std::unique_ptr<coro::net::dns::result>`. The `result` object contains information about the resolution status and resolved IP addresses.

**Example usage:**

```cpp
auto scheduler = std::make_shared<coro::io_scheduler>();
coro::net::dns::resolver<coro::io_scheduler> resolver{scheduler};

auto make_resolution_task = [&](coro::net::hostname hostname) -> coro::task<void> {
    co_await scheduler->schedule();
    auto result = co_await resolver.host_by_name(hostname);

    if (result->status() == coro::net::dns::status::complete) {
        for (const auto& ip_address : result->ip_addresses()) {
            std::cout << ip_address.to_string() << std::endl;
        }
    } else {
        std::cerr << "DNS resolution failed: " 
                  << coro::net::dns::to_string(result->status()) << std::endl;
    }
    co_return;
};

// Resolve "www.example.com"
coro::sync_wait(make_resolution_task("www.example.com"));
```

This example demonstrates how to use the `coro::net::dns::resolver` to asynchronously resolve a hostname. The `make_resolution_task` coroutine schedules itself on the I/O scheduler and then awaits the result of the DNS resolution. The resolved IP addresses are printed if the resolution is successful.

By using the `coro::net::dns::resolver`, you can integrate DNS resolution seamlessly into your asynchronous networking code, avoiding blocking operations and allowing for efficient utilization of resources.

