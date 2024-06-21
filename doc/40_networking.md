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
