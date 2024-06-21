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

## 4. Networking

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
