#include <boost/asio.hpp>
#include <iostream>

namespace asio = boost::asio;

int main() {
    // Create an I/O context - the core of Boost.Asio
    asio::io_context io;

    // Create a timer that expires after 1 second
    asio::steady_timer timer(io, asio::chrono::seconds(1));

    std::cout << "Starting timer for 1 second..." << std::endl;

    // Async wait with a completion handler
    timer.async_wait([](const boost::system::error_code& ec) {
        if (!ec) {
            std::cout << "Timer expired!" << std::endl;
        } else {
            std::cout << "Timer error: " << ec.message() << std::endl;
        }
    });

    // Run the I/O context - this blocks until all async operations complete
    io.run();

    // Demonstrate synchronous timer
    asio::steady_timer sync_timer(io, asio::chrono::milliseconds(500));
    std::cout << "Waiting 500ms synchronously..." << std::endl;
    sync_timer.wait();
    std::cout << "Synchronous wait complete!" << std::endl;

    return 0;
}
