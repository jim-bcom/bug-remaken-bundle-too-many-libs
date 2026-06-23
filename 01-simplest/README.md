## BUG DESCRIPTION
* A project that links against a header-only library within a conan dependency, when build also dragged all the non required shared library files contained in this conan dependency.
* More  generally, the bundle step at the end does not rely on the information given by the pkgconfig files used to perform the compilation.
* This has the effect of making a bundled app that contains too many files.

## SIMPLEST CASE TO REPRODUCE BUG

### BUILD AND RUN THE SAMPLE
* `mkdir build && cd build/`
* `rm -rf ../deploy/* &&  rm -rf * && qmake ../*.pro && bear -- make -j 12`
* run `./simplest `, it should read `NOOP tracer`
* go to `deploy/` dir, and observe that a lot of `opentelemetry` shared libs are present, whereas not needed.

### DESCRIPTION

* Project is linked against `opentelemetry-cpp-api`
* Not a realistic case: executable should link against `opentelemetry-cpp` to configure SDK, but this hightlights the issue
* compilation command lines show this does not depend on .so files

Include dir specified on compilation command:
```
g++ -c -pipe -isystem/home/user/.conan2/p/opent52fa77f39af59/p/include -DOPENTELEMETRY_ABI_VERSION_NO=1 [...] ]main.cpp

```
Library dir is specified, but no lib are listed with `-l` option at link:
```
g++ -Wl,-O1 -o simplest  main.o   -L/home/user/.conan2/p/opent52fa77f39af59/p/lib -ldl 
```
This follows what's in `.build-rules/linux-gcc-x86_64/shared/release/opentelemetry-cpp-api.pc`:
```
prefix=/home/user/.conan2/p/opent52fa77f39af59/p
libdir=${prefix}/lib
includedir=${prefix}/include
bindir=${prefix}/bin

Name: opentelemetry-cpp-api
Description: Conan component: opentelemetry-cpp-api
Version: 1.22.0
Libs: -L"${libdir}"
Cflags: -I"${includedir}" -DOPENTELEMETRY_ABI_VERSION_NO=1
```
But when running the build, there's a `bundle`step that does not seem to discriminate between the used libraries within a conan dependencies
bundle everything:
```
--------------- Conan bundle ---------------
===> bundling: opentelemetry-cpp-api/1.22.0
/home/user/.local/bin/conan install -o "&:shared=True" -s arch=x86_64 -s build_type=Release -s compiler.cppstd=17 -pr default -of /tmp/e8af9423-2702-44b5-a0a2-8f763671f207  -f json --requires=opentelemetry-cpp/1.22.0@ > /tmp/e8af9423-2702-44b5-a0a2-8f763671f207/opentelemetry-cpp_conanbuildinfo.json 2>/dev/null
```

* Conversly, if we specify `opentelemetry-cpp`, then the command line follows `.build-rules/linux-gcc-x86_64/shared/release/opentelemetry-cpp.pc`

```
prefix=/home/user/.conan2/p/opent52fa77f39af59/p
libdir=${prefix}/lib
includedir=${prefix}/include
bindir=${prefix}/bin

Name: opentelemetry-cpp
Description: Conan package: opentelemetry-cpp
Version: 1.22.0
Libs: -L"${libdir}"
Cflags: -I"${includedir}"
Requires: opentelemetry-cpp-opentelemetry_exporter_in_memory opentelemetry-cpp-opentelemetry_version opentelemetry-cpp-opentelemetry_http_client_curl opentelemetry-cpp-opentelemetry_proto opentelemetry-cpp-opentelemetry_metrics opentelemetry-cpp-opentelemetry_exporter_ostream_metrics opentelemetry-cpp-api opentelemetry-cpp-opentelemetry_common opentelemetry-cpp-opentelemetry_exporter_otlp_http_client opentelemetry-cpp-opentelemetry_resources opentelemetry-cpp-opentelemetry_trace opentelemetry-cpp-opentelemetry_logs opentelemetry-cpp-opentelemetry_exporter_ostream_span opentelemetry-cpp-opentelemetry_otlp_recordable opentelemetry-cpp-opentelemetry_exporter_zipkin_trace opentelemetry-cpp-opentelemetry_exporter_ostream_logs opentelemetry-cpp-opentelemetry_exporter_otlp_http opentelemetry-cpp-opentelemetry_exporter_otlp_http_metric opentelemetry-cpp-opentelemetry_exporter_otlp_http_log

```
And all the header dirs and libs are put on the command lines:
```
g++ -c -pipe -isystem/home/user/.conan2/p/opent52fa77f39af59/p/include -isystem/home/user/.conan2/p/libcu0f721d2e91b44/p/include -isystem/home/user/.conan2/p/opens02e83d05658f2/p/include -isystem/home/user/.conan2/p/opent52fa77f39af59/p/include -isystem/home/user/.conan2/p/protoee8f989771f2d/p/include -isystem/home/user/.conan2/p/zlib9780dc2008618/p/include -isystem/home/user/.conan2/p/protoee8f989771f2d/p/include -isystem/home/user/.conan2/p/abseic26da8f2890fa/p/include -DOPENTELEMETRY_ABI_VERSION_NO=1 -DCURL_STATICLIB=1 -Wno-attributes -Werror=switch-enum -Werror=unused-result -O2 -std=gnu++1z -Wall -Wextra -DMYVERSION=1.6.0 -D_NDEBUG=1 -DNDEBUG=1 -I/home/user/tmp/bugs/remaken-otel-api-bundle/01-simplest -I. -I/home/user/Qt/6.10.0/gcc_64/mkspecs/linux-g++ -o main.o /home/user/tmp/bugs/remaken-otel-api-bundle/01-simplest/main.cpp
```
```
g++ -Wl,-O1 -o simplest  main.o   -L/home/user/.conan2/p/opent52fa77f39af59/p/lib -L/home/user/.conan2/p/libcu0f721d2e91b44/p/lib -L/home/user/.conan2/p/opens02e83d05658f2/p/lib -L/home/user/.conan2/p/protoee8f989771f2d/p/lib -L/home/user/.conan2/p/zlib9780dc2008618/p/lib -L/home/user/.conan2/p/abseic26da8f2890fa/p/lib -lopentelemetry_version -lopentelemetry_metrics -lopentelemetry_exporter_ostream_metrics -lopentelemetry_exporter_ostream_span -lopentelemetry_exporter_zipkin_trace -lopentelemetry_exporter_ostream_logs -lopentelemetry_exporter_otlp_http -lopentelemetry_exporter_otlp_http_metric -lopentelemetry_exporter_otlp_http_log -lopentelemetry_otlp_recordable -lopentelemetry_trace -lopentelemetry_logs -lopentelemetry_resources -lopentelemetry_common -lopentelemetry_exporter_otlp_http_client -lopentelemetry_http_client_curl -lcurl -lssl -lcrypto -lopentelemetry_proto -lutf8_range -lprotoc -lprotobuf -lm -lz -lutf8_validity -labsl_log_internal_check_op -labsl_die_if_null -labsl_log_internal_conditions -labsl_log_internal_message -labsl_examine_stack -labsl_log_internal_format -labsl_log_internal_nullguard -labsl_log_internal_structured_proto -labsl_log_internal_proto -labsl_log_internal_log_sink_set -labsl_log_sink -labsl_log_entry -labsl_flags_internal -labsl_flags_marshalling -labsl_flags_reflection -labsl_flags_private_handle_accessor -labsl_flags_commandlineflag -labsl_flags_commandlineflag_internal -labsl_flags_config -labsl_flags_program_name -labsl_log_initialize -labsl_log_internal_globals -labsl_log_globals -labsl_vlog_config_internal -labsl_log_internal_fnmatch -labsl_raw_hash_set -labsl_hash -labsl_city -labsl_low_level_hash -labsl_hashtablez_sampler -labsl_random_distributions -labsl_random_seed_sequences -labsl_random_internal_pool_urbg -labsl_random_internal_randen -labsl_random_internal_randen_hwaes -labsl_random_internal_randen_hwaes_impl -labsl_random_internal_randen_slow -labsl_random_internal_platform -labsl_random_internal_seed_material -labsl_random_seed_gen_exception -labsl_statusor -labsl_status -labsl_cord -labsl_cordz_info -labsl_cord_internal -labsl_cordz_functions -labsl_exponential_biased -labsl_cordz_handle -labsl_crc_cord_state -labsl_crc32c -labsl_crc_internal -labsl_crc_cpu_detect -labsl_leak_check -labsl_bad_optional_access -labsl_strerror -labsl_str_format_internal -labsl_bad_variant_access -labsl_synchronization -labsl_graphcycles_internal -labsl_kernel_timeout_internal -labsl_stacktrace -labsl_symbolize -labsl_debugging_internal -labsl_demangle_internal -labsl_demangle_rust -labsl_decode_rust_punycode -labsl_utf8_for_code_point -labsl_malloc_internal -labsl_tracing_internal -labsl_time -labsl_civil_time -labsl_strings -labsl_strings_internal -labsl_string_view -labsl_base -lrt -labsl_spinlock_wait -labsl_int128 -labsl_throw_delegate -labsl_raw_logging_internal -labsl_log_severity -labsl_time_zone -lpthread -ldl
```


