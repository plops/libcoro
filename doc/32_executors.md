## 3.2 Executors

In libcoro, **executors** play a crucial role in managing the execution of tasks. They provide the mechanism for scheduling and running coroutines, effectively determining *where* and *when* the asynchronous operations within a task will be performed. Choosing the appropriate executor is essential for achieving the desired concurrency and performance characteristics of your application.

libcoro offers two primary executor implementations:

### 3.2.1. `coro::thread_pool`

The `coro::thread_pool` class represents a pool of worker threads that can concurrently execute tasks. It provides a straightforward way to offload computationally intensive or long-running operations to background threads, freeing up the main thread for other tasks, such as handling user interface events or responding to network requests.

#### Options and Usage

You can configure a `coro::thread_pool` using the `coro::thread_pool::options` structure, which allows you to specify:

- **`thread_count`**: The number of worker threads in the pool. By default, it uses `std::thread::hardware_concurrency()`, utilizing all available logical cores.
- **`on_thread_start_functor`**: An optional lambda function that will be invoked when each worker thread starts. This allows you to perform thread-specific setup, like setting thread priority or name.
- **`on_thread_stop_functor`**: An optional lambda function that will be invoked when each worker thread stops. This can be used for thread-specific cleanup.

Here's an example demonstrating how to create and use a `coro::thread_pool`:

```cpp
#include <coro/coro.hpp>

int main() {
    // Create a thread pool with 4 worker threads
    coro::thread_pool tp{coro::thread_pool::options{.thread_count = 4}};

    // Define a task that performs some work
    auto task = [&tp]() -> coro::task<int> {
        co_await tp.schedule(); // Schedule the task on the thread pool
        // Perform the work here...
        co_return 42;
    };

    // Execute the task and retrieve the result
    int result = coro::sync_wait(task());

    // Shutdown the thread pool
    tp.shutdown();
}
```

#### Scheduling Tasks and Managing Concurrency

To schedule a task for execution on the `coro::thread_pool`, you simply use the `co_await tp.schedule()` expression within your coroutine. This suspends the coroutine and adds it to the thread pool's internal queue. A worker thread will eventually pick up the task and resume its execution.

The thread pool automatically manages concurrency, ensuring that tasks are distributed among the available worker threads. You can control the level of concurrency by adjusting the `thread_count` option.

#### Thread Pool Shutdown

When you're finished using a `coro::thread_pool`, you should call the `shutdown()` method. This signals the worker threads to stop processing tasks and waits for them to complete any currently running operations. It's important to ensure that all tasks have finished or have been cancelled before shutting down the thread pool to avoid potential resource leaks or unexpected behavior.

### 3.2.2. `coro::io_scheduler`

The `coro::io_scheduler` class provides a more specialized executor designed for handling asynchronous I/O operations. It integrates with the operating system's event notification mechanisms (e.g., epoll on Linux) to efficiently monitor multiple file descriptors for events like readability, writability, or errors.

#### Options and Usage

The `coro::io_scheduler::options` structure allows you to configure the scheduler:

- **`thread_strategy`**: 
    -  `spawn`:  The scheduler will spawn a dedicated thread to process I/O events. This is the default behavior.
    - `manual`: Requires the user to manually call `process_events()` to drive the scheduler. Useful for integrating with existing event loops.
- **`on_io_thread_start_functor`**:  An optional lambda invoked when the dedicated event processor thread starts (only applicable in `spawn` mode).
- **`on_io_thread_stop_functor`**: An optional lambda invoked when the dedicated event processor thread stops (only applicable in `spawn` mode).
- **`pool`**: Options for the internal `coro::thread_pool` used to execute tasks. 
- **`execution_strategy`**:
    - `process_tasks_on_thread_pool`: Tasks are executed on the internal thread pool.
    - `process_tasks_inline`: Tasks are directly executed on the I/O thread itself (can be more efficient for small tasks). 

Here's a basic example illustrating `coro::io_scheduler` usage:

```cpp
#include <coro/coro.hpp>
#include <sys/eventfd.h>

int main() {
    auto trigger_fd = eventfd(0, EFD_CLOEXEC | EFD_NONBLOCK);

    // Create an io_scheduler with default options
    coro::io_scheduler s{};

    // Define a task that polls for readability on the eventfd
    auto task = [&s, trigger_fd]() -> coro::task<void> {
        co_await s.schedule(); 
        auto status = co_await s.poll(trigger_fd, coro::poll_op::read);
        REQUIRE(status == coro::poll_status::event);
        co_return;
    };

    // Schedule the task
    auto task_handle = task();
    task_handle.resume();

    // Trigger the eventfd to make it readable
    uint64_t value{1};
    write(trigger_fd, &value, sizeof(value));

    // Process events on the io_scheduler
    while (s.process_events() > 0);

    // Shutdown the io_scheduler
    s.shutdown();
    close(trigger_fd);
}
```

#### Scheduling Tasks with Delays

The `coro::io_scheduler` allows you to schedule tasks with specific delays using the `schedule_after(amount)` and `schedule_at(time)` methods. These functions return a `coro::task<void>` that will be automatically resumed after the specified duration or at the designated time point.

#### Polling for I/O Events

You can use the `poll(fd, op, timeout)` method to await I/O events on a file descriptor. The `op` parameter specifies the type of event to wait for (e.g., `coro::poll_op::read`, `coro::poll_op::write`). The optional `timeout` parameter sets a maximum wait duration. The method returns a `coro::task<poll_status>`, which resolves to `coro::poll_status::event` if the event occurred, `coro::poll_status::timeout` if the timeout expired, or other values indicating errors or socket closure.

#### Manual vs. Spawned Thread Strategies

The `thread_strategy` option in `coro::io_scheduler::options` allows you to choose between two modes for processing I/O events:

- **`spawn` (default)**: The scheduler creates a dedicated thread to handle events. This is the most convenient option for most use cases, as it allows the scheduler to run independently without blocking the main thread.
- **`manual`**: In this mode, you need to explicitly call the `process_events(timeout)` method to drive the scheduler. This is useful for scenarios where you want to integrate the scheduler with an existing event loop or thread.

#### Integrating with External Event Loops or Threads

If you need to integrate `coro::io_scheduler` with an external event loop or thread, you can use the `manual` thread strategy and call `process_events()` from within your external loop. This allows you to control when and how the scheduler processes events, giving you fine-grained control over the interaction between your application and the asynchronous operations managed by libcoro.

By understanding the different executors and their capabilities, you can effectively leverage libcoro to manage concurrency, handle asynchronous I/O operations, and build responsive and efficient applications.
