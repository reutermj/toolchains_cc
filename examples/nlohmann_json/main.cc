#include <iostream>
#include <string>

#include <nlohmann/json.hpp>

using json = nlohmann::json;

int main() {
    // Create a JSON object
    json person = {
        {"name", "Alice"},
        {"age", 30},
        {"email", "alice@example.com"},
        {"is_active", true},
        {"scores", {95, 87, 92}},
        {"address", {
            {"city", "New York"},
            {"zip", "10001"}
        }}
    };

    // Serialize to string
    std::string serialized = person.dump(2);  // 2-space indent
    std::cout << "Serialized JSON:" << std::endl;
    std::cout << serialized << std::endl;
    std::cout << std::endl;

    // Parse from string
    std::string json_str = R"({
        "name": "Bob",
        "age": 25,
        "hobbies": ["reading", "gaming"]
    })";

    json parsed = json::parse(json_str);
    std::cout << "Parsed JSON:" << std::endl;
    std::cout << "  Name: " << parsed["name"] << std::endl;
    std::cout << "  Age: " << parsed["age"] << std::endl;
    std::cout << "  Hobbies: " << parsed["hobbies"] << std::endl;

    return 0;
}
