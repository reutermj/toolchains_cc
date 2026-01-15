#include <fmt/core.h>
#include <fmt/chrono.h>
#include <fmt/ranges.h>

#include <chrono>
#include <vector>

int main() {
    // Basic formatting
    fmt::print("Hello, {}!\n", "world");

    // Numeric formatting
    fmt::print("Integer: {}, Hex: {:#x}, Binary: {:#b}\n", 42, 42, 42);
    fmt::print("Float: {:.2f}, Scientific: {:.2e}\n", 3.14159, 3.14159);

    // Positional arguments
    fmt::print("{1} comes before {0}\n", "second", "first");

    // Named arguments
    fmt::print("{name} is {age} years old\n",
               fmt::arg("name", "Alice"),
               fmt::arg("age", 30));

    // Date/time formatting
    auto now = std::chrono::system_clock::now();
    fmt::print("Current time: {:%Y-%m-%d %H:%M:%S}\n", now);

    // Container formatting
    std::vector<int> numbers = {1, 2, 3, 4, 5};
    fmt::print("Numbers: {}\n", numbers);

    // Format to string
    std::string result = fmt::format("The answer is {}", 42);
    fmt::print("Formatted string: {}\n", result);

    return 0;
}
