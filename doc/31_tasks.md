## 3.1. Coroutines and Tasks

libcoro provides a simple yet powerful abstraction for working with coroutines through the `coro::task<T>` class. This class encapsulates the entire lifecycle of a coroutine, from creation to completion, and provides a convenient interface for interacting with its execution. 

### 3.1.1. Understanding `coro::task<T>`

A `coro::task<T>` represents a coroutine that, upon completion, will return a value of type `T`. The task itself does not directly contain the result, instead, it manages the coroutine's execution and provides access to the `promise` object where the result is stored.

**Key elements of `coro::task<T>`:**

- **Promise type**: Each `coro::task<T>` has an associated `promise_type`, which is a specialized version of `std::coroutine_handle` that provides methods for setting the coroutine's return value and handling exceptions. It acts as a communication channel between the coroutine and the outside world.
- **Coroutine handle**: Internally, the task stores a `std::coroutine_handle<>` that represents the actual coroutine. This handle allows control over the coroutine's execution, enabling suspension, resumption, and checking its completion status.
- **Return value and exception handling**: The `coro::task<T>` class provides methods for accessing the coroutine's return value or any exceptions thrown within it. This allows for seamless integration with regular C++ exception handling mechanisms.

### 3.1.2. Task Lifecycle

The lifecycle of a `coro::task<T>` follows these stages:

1. **Creation**: A task is created when a coroutine function that returns `coro::task<T>` is called. Initially, the task is in a suspended state.
2. **Suspension**: The coroutine suspends its execution when it encounters a `co_await` expression. This gives control back to the caller, allowing other tasks to execute concurrently.
3. **Resumption**: The coroutine can be resumed using the task's `resume()` method. Resuming the task allows the coroutine to continue its execution from the point where it was suspended.
4. **Completion**: The coroutine completes when it reaches a `co_return` statement or when an uncaught exception is thrown. The task's `is_ready()` method can be used to check if the coroutine has completed.

### 3.1.3. Moving and Copying

`coro::task<T>` is designed to be easily moved, allowing efficient transfer of ownership between different parts of your code. Copying a task is explicitly disallowed to prevent unintended shared state and potential data races in concurrent scenarios.

### 3.1.4 Examples

**Simple task creation and execution:**

```c++
#include <coro/coro.hpp>
#include <iostream>

auto my_task() -> coro::task<int> {
  co_return 42;
}

int main() {
  auto task = my_task(); // Task is created but suspended.
  task.resume(); // Resume the task, it completes and returns 42.
  std::cout << task.promise().result() << std::endl; // Output: 42
}
```

**Task with suspension and resumption:**

```c++
#include <coro/coro.hpp>
#include <iostream>
#include <chrono>
#include <thread>

auto delayed_task() -> coro::task<std::string> {
  std::cout << "Task started..." << std::endl;
  co_await std::suspend_always{}; // Suspend execution.
  std::this_thread::sleep_for(std::chrono::seconds(1)); // Simulate delay.
  std::cout << "Task resuming..." << std::endl;
  co_return "Delayed result";
}

int main() {
  auto task = delayed_task();
  task.resume();
  std::cout << "Waiting for task to complete..." << std::endl;
  while (!task.is_ready()) {
    // Do other things while the task is suspended.
  }
  std::cout << task.promise().result() << std::endl; // Output: Delayed result
}
```

These examples demonstrate the basic usage of `coro::task<T>` for creating, resuming, and retrieving results from coroutines. The power of coroutines lies in their ability to suspend and resume execution, enabling efficient asynchronous operations and concurrent task management. In the following sections, we will delve into the mechanisms for managing task execution through executors and synchronizing them using various primitives provided by libcoro.
