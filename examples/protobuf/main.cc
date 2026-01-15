#include <iostream>
#include <string>

#include "person.pb.h"

int main() {
    // Create a Person message
    example::Person person;
    person.set_name("Alice");
    person.set_age(30);
    person.set_email("alice@example.com");

    // Serialize to string
    std::string serialized;
    if (!person.SerializeToString(&serialized)) {
        std::cerr << "Failed to serialize person." << std::endl;
        return 1;
    }

    std::cout << "Serialized person: " << serialized.size() << " bytes" << std::endl;

    // Deserialize from string
    example::Person parsed;
    if (!parsed.ParseFromString(serialized)) {
        std::cerr << "Failed to parse person." << std::endl;
        return 1;
    }

    std::cout << "Parsed person:" << std::endl;
    std::cout << "  Name: " << parsed.name() << std::endl;
    std::cout << "  Age: " << parsed.age() << std::endl;
    std::cout << "  Email: " << parsed.email() << std::endl;

    return 0;
}
