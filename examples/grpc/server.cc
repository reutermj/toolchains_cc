#include <iostream>
#include <memory>
#include <string>

#include <grpcpp/grpcpp.h>

#include "greeter.grpc.pb.h"

class GreeterServiceImpl final : public greeter::Greeter::Service {
    grpc::Status SayHello(grpc::ServerContext* context,
                          const greeter::HelloRequest* request,
                          greeter::HelloReply* reply) override {
        std::string prefix("Hello ");
        reply->set_message(prefix + request->name());
        return grpc::Status::OK;
    }
};

int main(int argc, char** argv) {
    std::string server_address("0.0.0.0:50051");
    GreeterServiceImpl service;

    grpc::ServerBuilder builder;
    builder.AddListeningPort(server_address, grpc::InsecureServerCredentials());
    builder.RegisterService(&service);

    std::unique_ptr<grpc::Server> server(builder.BuildAndStart());
    std::cout << "Server listening on " << server_address << std::endl;
    std::cout << "gRPC version: " << grpc::Version() << std::endl;

    server->Wait();
    return 0;
}
