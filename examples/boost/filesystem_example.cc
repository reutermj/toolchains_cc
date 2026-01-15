#include <boost/filesystem.hpp>
#include <iostream>

namespace fs = boost::filesystem;

int main() {
    fs::path current = fs::current_path();
    std::cout << "Current path: " << current << std::endl;

    // Path manipulation
    fs::path example = current / "subdir" / "file.txt";
    std::cout << "Example path: " << example << std::endl;
    std::cout << "Parent path: " << example.parent_path() << std::endl;
    std::cout << "Filename: " << example.filename() << std::endl;
    std::cout << "Extension: " << example.extension() << std::endl;

    // Path properties
    std::cout << "Current path exists: " << std::boolalpha << fs::exists(current)
              << std::endl;
    std::cout << "Current path is directory: " << fs::is_directory(current)
              << std::endl;

    // List directory contents
    std::cout << "\nDirectory contents:" << std::endl;
    for (const auto& entry : fs::directory_iterator(current)) {
        std::cout << "  " << entry.path().filename() << std::endl;
    }

    return 0;
}
