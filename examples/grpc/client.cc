#include <iostream>
#include <memory>
#include <string>

#include <grpcpp/grpcpp.h>

#include "greeter.grpc.pb.h"

class GreeterClient {
  public:
    GreeterClient(std::shared_ptr<grpc::Channel> channel)
        : stub_(greeter::Greeter::NewStub(channel)) {}

    std::string SayHello(const std::string& name) {
        greeter::HelloRequest request;
        request.set_name(name);

        greeter::HelloReply reply;
        grpc::ClientContext context;

        grpc::Status status = stub_->SayHello(&context, request, &reply);

        if (status.ok()) {
            return reply.message();
        } else {
            std::cerr << "RPC failed: " << status.error_message() << std::endl;
            return "";
        }
    }

  private:
    std::unique_ptr<greeter::Greeter::Stub> stub_;
};

int main(int argc, char** argv) {
    std::string target_str = "localhost:50051";

    std::cout << "gRPC version: " << grpc::Version() << std::endl;
    std::cout << "Connecting to " << target_str << std::endl;

    GreeterClient greeter(
        grpc::CreateChannel(target_str, grpc::InsecureChannelCredentials()));

    std::string name("World");
    std::string reply = greeter.SayHello(name);

    if (!reply.empty()) {
        std::cout << "Greeter received: " << reply << std::endl;
    }

    return 0;
}
