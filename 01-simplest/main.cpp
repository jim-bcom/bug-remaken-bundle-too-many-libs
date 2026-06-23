#include <iostream>

#include <opentelemetry/trace/provider.h>

using opentelemetry::trace::TracerProvider;
using opentelemetry::trace::Provider;
using opentelemetry::trace::NoopTracer;

auto main() -> int {
    auto provider = Provider::GetTracerProvider();
    auto tracer = provider->GetTracer("verification-tracer");
    if (dynamic_cast<NoopTracer*>(tracer.get())) {
        std::cout << "NOOP tracer" << std::endl;
    } else {
        std::cout << "Not a NOOP tracer" << std::endl;
    }
}
