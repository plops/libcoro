## 3.3 Synchronization Primitives

In concurrent programming, it is crucial to synchronize access to shared resources to avoid race conditions and maintain data consistency. Libcoro provides a suite of synchronization primitives, tailored for use with coroutines, that enable safe and efficient coordination between concurrently executing tasks.

### 3.3.1 `coro::event`

The `coro::event` class acts as a signal, allowing one or more tasks to wait for a specific condition to occur.  It provides a simple yet powerful mechanism for coordinating asynchronous operations.

**Key Methods:**

- `set(resume_order_policy policy = resume_order_policy::lifo)`: Signals the event, resuming all waiting coroutines. The `policy` parameter determines the order in which waiting coroutines are resumed (LIFO by default, FIFO available).
- `reset()`: Resets the event to an unsignaled state.
- `is_set()`: Returns `true` if the event is currently signaled, `false` otherwise.

**Usage Example:**

```cpp
coro::event data_ready{};

auto producer_task = [&]() -> coro::task<void> {
    // Perform data processing...
    data_ready.set();
    co_return;
};

auto consumer_task = [&]() -> coro::task<void> {
    co_await data_ready; // Suspend until data_ready is signaled.
    // Consume the processed data...
    co_return;
};
```

### 3.3.2 `coro::mutex`

The `coro::mutex` class provides a mutual exclusion mechanism, ensuring that only one task can access a shared resource at a time.  It prevents data corruption caused by concurrent modifications.

**Key Methods:**

- `lock_operation lock()`: Acquires the mutex lock, suspending the current coroutine until the lock is available.  Returns a `coro::scoped_lock` object for RAII-style lock management.
- `bool try_lock()`: Attempts to acquire the mutex lock without suspending. Returns `true` if the lock was acquired, `false` otherwise.
- `void unlock()`: Releases the mutex lock, potentially allowing another waiting coroutine to acquire it.

**Usage Example:**

```cpp
coro::mutex shared_data_mutex{};

auto task1 = [&]() -> coro::task<void> {
    auto lock = co_await shared_data_mutex.lock(); // Acquire the lock.
    // Access and modify the shared data...
};

auto task2 = [&]() -> coro::task<void> {
    auto lock = co_await shared_data_mutex.lock(); // Acquire the lock.
    // Access and modify the shared data...
};
```

### 3.3.3 `coro::shared_mutex`

The `coro::shared_mutex` class extends the concept of mutual exclusion by allowing either shared or exclusive access to a resource.  Multiple readers can hold shared locks concurrently, but only one writer can hold an exclusive lock.

**Key Methods:**

- `lock_operation lock()`: Acquires an exclusive lock, suspending until available.
- `shared_lock_operation lock_shared()`: Acquires a shared lock, suspending until available.
- `bool try_lock()`: Attempts to acquire an exclusive lock without suspending.
- `bool try_lock_shared()`: Attempts to acquire a shared lock without suspending.
- `void unlock()`: Releases an exclusive lock.
- `void unlock_shared()`: Releases a shared lock.

**Usage Example:**

```cpp
coro::shared_mutex resource_mutex{tp}; // Requires an executor for shared lock management.

auto reader_task = [&]() -> coro::task<void> {
    auto lock = co_await resource_mutex.lock_shared(); // Acquire a shared lock.
    // Read the resource...
};

auto writer_task = [&]() -> coro::task<void> {
    auto lock = co_await resource_mutex.lock(); // Acquire an exclusive lock.
    // Modify the resource...
};
```

### 3.3.4 `coro::semaphore`

The `coro::semaphore` class manages a limited number of resources, allowing tasks to acquire and release them asynchronously. It is useful for controlling concurrency and preventing resource exhaustion.

**Key Methods:**

- `acquire_operation acquire()`: Acquires a resource, suspending the coroutine if none are available. Returns a `semaphore::acquire_operation` object.
- `void release()`: Releases a resource, potentially allowing a waiting coroutine to acquire it.
- `bool try_acquire()`: Attempts to acquire a resource without suspending.

**Usage Example:**

```cpp
coro::semaphore resource_pool{4}; // Manages 4 resources.

auto task = [&]() -> coro::task<void> {
    auto result = co_await resource_pool.acquire(); // Acquire a resource.
    if (result == coro::semaphore::acquire_result::acquired) {
        // Use the acquired resource...
        resource_pool.release(); // Release the resource.
    } else {
        // Handle semaphore exhaustion...
    }
};
```

### 3.3.5 `coro::latch`

The `coro::latch` class provides a countdown mechanism for synchronizing multiple tasks.  A latch starts with a given count, and tasks can wait for the latch to reach zero before proceeding.

**Key Methods:**

- `await_suspend(std::coroutine_handle<> awaiting_coroutine)`: Suspends the current coroutine until the latch count reaches zero.
- `void count_down(uint64_t n = 1)`: Decrements the latch count by `n`.
- `uint64_t remaining()`: Returns the current latch count.

**Usage Example:**

```cpp
coro::latch task_completion_latch{3}; // Wait for 3 tasks to complete.

auto worker_task = [&]() -> coro::task<void> {
    // Perform some work...
    task_completion_latch.count_down();
    co_return;
};

// Create and start the worker tasks...

co_await task_completion_latch; // Wait for all worker tasks to finish.
// Proceed after all tasks have completed...
```

These synchronization primitives, designed specifically for coroutines, provide powerful tools for building complex and efficient concurrent applications with libcoro. Each primitive offers distinct capabilities for managing shared resources, signaling events, and coordinating the execution of concurrent tasks, enabling developers to create sophisticated asynchronous workflows in C++.