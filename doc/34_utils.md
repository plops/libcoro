## 3.4. Utility Classes

libcoro provides utility classes that simplify common asynchronous programming patterns and data management between coroutines. These classes streamline development and enhance code readability.

### 3.4.1. `coro::ring_buffer<T, N>`

The `coro::ring_buffer<T, N>` class implements a thread-safe, lock-free ring buffer with a fixed capacity of `N` elements of type `T`. Ring buffers are highly efficient for data exchange between producers and consumers in concurrent systems.

#### 3.4.1.1. Producing and Consuming Data

- **`produce(T&& t)`:** This method asynchronously adds an element `t` to the ring buffer. It returns a `coro::task<coro::rb::produce_result>` that completes when the element is successfully added or the buffer is full. 
  - The `coro::rb::produce_result` enum indicates whether the element was produced (`produced`) or if the buffer was full (`full`).
- **`consume()`:** This method asynchronously retrieves an element from the ring buffer. It returns a `coro::task<std::optional<T>>` that completes when an element is available or the buffer is empty.
  - If an element is available, the task returns a `std::optional` containing the element.
  - If the buffer is empty, the task returns an empty `std::optional`.

#### 3.4.1.2. Handling Buffer State

- **`empty()`:** This method returns `true` if the ring buffer is empty, otherwise `false`.
- **`notify_waiters()`:** This method notifies all coroutines waiting on the `consume()` method that the ring buffer is shutting down. Consumers should check for an empty `std::optional` return from `consume()` after receiving this notification.

#### 3.4.1.3. Example

```c++
#include <coro/coro.hpp>
#include <iostream>

int main() {
  coro::thread_pool tp{};
  coro::ring_buffer<int, 16> rb{};

  auto producer_task = [&]() -> coro::task<void> {
    co_await tp.schedule();
    for (int i = 0; i < 20; ++i) {
      auto result = co_await rb.produce(i);
      if (result == coro::rb::produce_result::full) {
        std::cout << "Producer: Buffer full, waiting...\n";
        co_await tp.yield(); // Wait for space in the buffer
        i--;                // Retry producing the same value
      } else {
        std::cout << "Producer: Produced " << i << std::endl;
      }
    }
    rb.notify_waiters(); // Signal shutdown
  };

  auto consumer_task = [&]() -> coro::task<void> {
    co_await tp.schedule();
    while (true) {
      auto element = co_await rb.consume();
      if (!element.has_value()) {
        std::cout << "Consumer: Ring buffer shutting down.\n";
        break;
      }
      std::cout << "Consumer: Consumed " << *element << std::endl;
      co_await tp.yield();
    }
  };

  coro::sync_wait(coro::when_all(producer_task(), consumer_task()));
}
```

### 3.4.2. `coro::generator<T>`

The `coro::generator<T>` class enables the creation of custom iterators that generate sequences of values asynchronously. These generators leverage the `co_yield` keyword to suspend execution and produce values on demand.

#### 3.4.2.1. Using `co_yield`

Within a generator function, you use `co_yield value` to produce a value and suspend the generator's execution. The next time the generator is iterated, it will resume from the point after the `co_yield` statement.

#### 3.4.2.2. Consuming Values

You can consume values from a generator using range-based for loops or by directly iterating using the generator's `begin()` and `end()` methods.

#### 3.4.2.3. Example

```c++
#include <coro/coro.hpp>
#include <iostream>

auto fibonacci() -> coro::generator<int> {
  int a = 0;
  int b = 1;
  while (true) {
    co_yield a;
    auto next = a + b;
    a = b;
    b = next;
  }
}

int main() {
  for (auto i : fibonacci() | std::views::take(10)) {
    std::cout << i << ' ';
  }
  std::cout << std::endl;
}
```

This example demonstrates a Fibonacci sequence generator that produces an infinite sequence of Fibonacci numbers. The `std::views::take(10)` limits the output to the first 10 Fibonacci numbers.
