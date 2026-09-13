# Benchmark environment

## System

- Operating system: Linux x86_64 (CachyOS / Arch Linux)
- CPU: Intel Core i3-6006U
- CPU topology: 2 cores / 4 threads
- Relevant ISA: AVX2
- RAM: approximately 20 GB DDR4-2133
- CPU governor: `powersave`
- Primary runtime thread count: 2

## Runtime and build

- `llama.cpp` tag: `b10883`
- `llama.cpp` commit: `91f6a6cf361385700bbe15981f0f39909df77498`
- `llama-cli`: `0.4.0-dev` (build 1, commit `91f6a6c`)
- Compiler: GNU 16.2.1
- Build type: Release
- Backend: CPU-only
- `GGML_NATIVE=ON`