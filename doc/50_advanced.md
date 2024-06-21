## 5. Advanced Topics

This section delves into more advanced usage scenarios and concepts within libcoro, offering insights for developers seeking to leverage its full potential and integrate it with existing systems.

### 5.1. Task Cancellation and Cooperative Interruption

While libcoro does not provide direct mechanisms for forceful task termination, it embraces a cooperative cancellation model. Coroutines can check for interruption requests and gracefully exit their execution loops. This approach allows for resource cleanup and prevents potential data corruption or inconsistencies.

Consider incorporating cancellation points within long-running coroutines where external factors might necessitate early termination. These points can involve checking a shared flag or event, allowing external actors to signal interruption requests.

**Example:**

```cpp
auto long_running_task(coro::thread_pool& tp, std::atomic<bool>& cancel_flag) -> coro::task<void> {
    co_await tp.schedule();
    while (!cancel_flag.load()) {
        // Perform a unit of work.
        co_await tp.yield(); // Yield to allow other tasks to execute and cancellation checks.
    }
    std::cerr << "Task interrupted gracefully.\n";
    co_return;
}
```

### 5.2. Custom Awaitable Types and Awaiter Implementations

libcoro's flexibility extends to defining your own awaitable types and customizing their awaiter behavior. This allows for seamless integration with existing asynchronous APIs or implementing specialized synchronization mechanisms tailored to your application's needs.

To define a custom awaitable, implement the following three methods within your type:

- `await_ready()`: Returns `true` if the awaitable is immediately ready (synchronous completion), `false` otherwise.
- `await_suspend(std::coroutine_handle<>)`: Suspends the current coroutine, typically storing the provided `coroutine_handle` for later resumption. Returns `true` if suspension occurred, `false` if resumption should happen immediately.
- `await_resume()`: Returns the result of the asynchronous operation or throws an exception if an error occurred.

**Example:**

```cpp
class MyAwaitable {
public:
    // ...

    bool await_ready() const { return false; } // Always asynchronous.
    bool await_suspend(std::coroutine_handle<> awaiting) {
        m_awaiting = awaiting;
        // Initiate the asynchronous operation.
        return true;
    }
    int await_resume() { return m_result; } // Return the result.

private:
    std::coroutine_handle<> m_awaiting;
    int m_result;
};
```

### 5.3. Integration with Existing Asynchronous Libraries or Frameworks

libcoro can coexist and integrate with other asynchronous libraries or frameworks, enabling you to leverage their specific functionalities while benefiting from libcoro's coroutine-based programming model.

Consider using `coro::event` to bridge between libcoro and external event loops or completion mechanisms. When an external event loop signals completion, the corresponding `coro::event` can be set, resuming awaiting coroutines within libcoro's context.

**Example:**

```cpp
// Assume 'external_async_operation' returns an opaque handle for tracking completion.
auto handle = external_async_operation();

coro::event completion_event;

// Register a callback with the external library to set the event upon completion.
external_register_completion_callback(handle, [&completion_event]() { completion_event.set(); });

// Await the event within a libcoro task.
co_await completion_event;
```

### 5.4. Performance Considerations and Best Practices

- **Minimize Suspension Points:** Coroutine suspension and resumption involve context switching, which can incur overhead. Design your coroutines to minimize unnecessary suspension points, especially within performance-critical sections.
- **Choose Appropriate Executors:** Select executors that align with the characteristics of your tasks. For I/O-bound tasks, use `coro::io_scheduler`. For CPU-bound tasks, use `coro::thread_pool` with an appropriate thread count.
- **Avoid Blocking Calls:** Never use blocking system calls or long-running synchronous operations within coroutines. Instead, utilize asynchronous equivalents or delegate blocking operations to dedicated threads.
- **Optimize Memory Allocations:** Frequent memory allocations within coroutines can impact performance. Consider using custom allocators or pre-allocating buffers to reduce allocation overhead.
- **Profile and Benchmark:**  Measure the performance of your coroutine-based code to identify bottlenecks and optimize critical sections.

### 5.5. Debugging Tips for Coroutine-Based Code

Debugging coroutine-based code can be challenging due to their asynchronous nature and suspension points. Utilize the following strategies:

- **Logging:** Insert logging statements within coroutines to track their execution flow and state changes.
- **Debugger Breakpoints:** Set breakpoints within coroutines to inspect their state and variables. However, be aware that breakpoints might not trigger as expected due to coroutine suspension.
- **Coroutine Dumps:** Utilize tools or techniques that provide insights into the current state of all active coroutines within an executor, allowing for analysis of their suspension points and call stacks.

By exploring these advanced concepts and techniques, you can harness libcoro's full power and flexibility, designing efficient and scalable asynchronous applications while integrating it seamlessly with your existing development ecosystem.
