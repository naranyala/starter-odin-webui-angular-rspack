# Documentation Index

This document provides a comprehensive index of all documentation available in this project.

## Getting Started

| Document | Description |
|----------|-------------|
| [README.md](../README.md) | Project overview and quick start |
| [src/README.md](../src/README.md) | Source code structure guide |
| [tests/README.md](../tests/README.md) | Testing framework guide |

## Core Documentation

### Architecture

| Document | Description |
|----------|-------------|
| [docs/DI_SYSTEM.md](DI_SYSTEM.md) | Dependency Injection system |
| [docs/COMMUNICATION_APPROACHES.md](COMMUNICATION_APPROACHES.md) | Backend-frontend communication patterns |
| [docs/COMMUNICATION_EXAMPLES.md](COMMUNICATION_EXAMPLES.md) | Communication usage examples |

### Build and Deploy

| Document | Description |
|----------|-------------|
| [docs/BUILD_SYSTEM.md](BUILD_SYSTEM.md) | Build pipeline documentation |
| [docs/WEBUI_INTEGRATION_EVALUATION.md](WEBUI_INTEGRATION_EVALUATION.md) | WebUI integration evaluation |
| [docs/WEBUI_CIVETWEB_SUMMARY.md](WEBUI_CIVETWEB_SUMMARY.md) | CivetWeb integration summary |

### Development

| Document | Description |
|----------|-------------|
| [docs/ERROR_HANDLING_GUIDE.md](ERROR_HANDLING_GUIDE.md) | Error handling usage guide |
| [docs/ERROR_HANDLING_SUMMARY.md](ERROR_HANDLING_SUMMARY.md) | Error handling technical summary |
| [utils/README.md](../utils/README.md) | Utilities documentation |

## Quick Reference

### Build Commands

```bash
./run.sh build      # Build all components
./run.sh run        # Run application
./run.sh dev        # Development mode
./run.sh clean      # Clean build artifacts
./run.sh test       # Run tests
./run.sh help       # Show help
```

### Import Paths

```odin
// Core modules
import di "src/lib/di"
import comms "src/lib/comms"
import errors "src/lib/errors"
import utils "src/lib/utils"
import webui "src/lib/webui_lib"

// Application modules
import models "src/models"
import services "src/services"

// Testing
import testing "src/testing"
```

### Common Patterns

#### Dependency Injection

```odin
container := di.create_container()
defer di.destroy_container(&container)

di.register_singleton(&container, "logger", size_of(Logger))
logger := cast(^Logger) di.resolve(&container, "logger")
```

#### Error Handling

```odin
result := some_operation()
if errors.check_result(result) {
    errors.log_error(result.err)
    return result
}
```

#### Communication

```odin
comms.comms_init()
comms.comms_rpc("methodName", handler_proc)
comms.comms_on("eventName", event_handler)
```

## Documentation by Topic

### Application Structure

- [src/README.md](../src/README.md) - Source organization
- [README.md](../README.md) - Project structure

### Backend Development

- [docs/DI_SYSTEM.md](DI_SYSTEM.md) - Dependency injection
- [docs/COMMUNICATION_APPROACHES.md](COMMUNICATION_APPROACHES.md) - Communication patterns
- [docs/ERROR_HANDLING_GUIDE.md](ERROR_HANDLING_GUIDE.md) - Error handling

### Frontend Development

- [frontend/README.md](../frontend/README.md) - Angular setup
- [docs/COMMUNICATION_EXAMPLES.md](COMMUNICATION_EXAMPLES.md) - Frontend-backend communication

### Build and Deployment

- [docs/BUILD_SYSTEM.md](BUILD_SYSTEM.md) - Build process
- [docs/WEBUI_CIVETWEB_SUMMARY.md](WEBUI_CIVETWEB_SUMMARY.md) - Web server details

### Testing

- [tests/README.md](../tests/README.md) - Testing guide
- [testing/README.md](../testing/README.md) - Test framework

### Utilities

- [utils/README.md](../utils/README.md) - Utility modules
- [utils/examples.odin](../utils/examples.odin) - Usage examples

## API References

### DI System

- `create_container()` - Create DI container
- `register_singleton()` - Register singleton provider
- `register_factory()` - Register factory provider
- `resolve()` - Resolve dependency
- `has()` - Check if token registered

See [docs/DI_SYSTEM.md](DI_SYSTEM.md) for complete API reference.

### Communication Layer

- `comms_init()` - Initialize communication
- `comms_rpc()` - Register RPC handler
- `comms_on()` - Subscribe to event
- `comms_send()` - Send message

See [docs/COMMUNICATION_APPROACHES.md](COMMUNICATION_APPROACHES.md) for complete API reference.

### Error Handling

- `errors.new()` - Create error
- `errors.result_ok()` - Create success result
- `errors.result_error()` - Create error result
- `errors.check()` - Check error
- `errors.log_error()` - Log error

See [docs/ERROR_HANDLING_GUIDE.md](ERROR_HANDLING_GUIDE.md) for complete API reference.

### Utilities

- `file_read()` / `file_write()` - File operations
- `config_create()` - Create config manager
- `logger_create()` - Create logger
- `clipboard_copy()` / `clipboard_paste()` - Clipboard operations
- `dialog_open_file()` - Open file dialog
- `system_info()` - Get system information

See [utils/README.md](../utils/README.md) for complete API reference.

## Examples

### Working Examples

| Example | Location | Description |
|---------|----------|-------------|
| DI Demo | `examples/di_demo.odin` | Dependency injection demonstration |
| Minimal | `examples/minimal/` | Minimal application |
| Utils Examples | `utils/examples.odin` | Utilities usage examples |
| DI Tests | `tests/di_tests.odin` | DI system tests |

### Code Snippets

See individual documentation files for code snippets and usage examples.

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Build fails | Check [BUILD_SYSTEM.md](BUILD_SYSTEM.md) troubleshooting section |
| DI resolution fails | Check [DI_SYSTEM.md](DI_SYSTEM.md) troubleshooting section |
| Communication errors | Check [COMMUNICATION_APPROACHES.md](COMMUNICATION_APPROACHES.md) |
| Test failures | Check [tests/README.md](../tests/README.md) |

### Getting Help

1. Check relevant documentation
2. Review examples
3. Search existing issues
4. Open new issue

## Version Information

| Component | Version |
|-----------|---------|
| WebUI | 2.5.0-beta.4 |
| CivetWeb | 1.17 |
| Odin | dev-2025-04 or later |

## Contributing

When contributing documentation:

1. Follow existing format and style
2. Include code examples
3. Update documentation index
4. Test all code snippets

## License

Documentation is provided under the same license as the project (MIT).

## Last Updated

This documentation index was last updated for the current release.
