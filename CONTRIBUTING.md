# Contributing to Odin WebUI Angular Rspack

Thank you for your interest in contributing to Odin WebUI Angular Rspack! We welcome contributions from everyone.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Development Workflow](#development-workflow)
3. [Code Style](#code-style)
4. [Testing](#testing)
5. [Pull Request Process](#pull-request-process)
6. [Communication](#communication)

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Odin Compiler**: [Download Odin](https://github.com/odin-lang/odin)
- **Node.js**: Version 18 or later
- **Bun**: Preferred package manager (or npm)
- **Git**: For version control

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/starter-odin-webui-angular-rspack.git
   cd starter-odin-webui-angular-rspack
   ```
3. Add the upstream repository:
   ```bash
   git remote add upstream https://github.com/anomalyco/starter-odin-webui-angular-rspack.git
   ```

### Install Dependencies

```bash
# Install frontend dependencies
cd frontend
bun install

# Build WebUI library (if needed)
cd ../thirdparty/webui
make release
cd ../..
```

## Development Workflow

### Branch Naming

Use descriptive branch names following this convention:

- `feature/` - New features (e.g., `feature/dark-mode`)
- `fix/` - Bug fixes (e.g., `fix/memory-leak`)
- `docs/` - Documentation changes (e.g., `docs/api-reference`)
- `refactor/` - Code refactoring (e.g., `refactor/di-system`)
- `test/` - Test updates (e.g., `test/integration-tests`)

### Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
type(scope): description

[optional body]

[optional footer(s)]
```

Examples:
- `feat: add dark mode support`
- `fix: resolve memory leak in event bus`
- `docs: update API reference in README`

### Building and Running

Use the provided `run.sh` script for development:

```bash
# Build and run
./run.sh

# Build only
./run.sh --build

# Run only (requires previous build)
./run.sh --run

# Run tests
./run.sh --test

# Clean build artifacts
./run.sh --clean

# Show help
./run.sh --help
```

## Code Style

### Odin

- Follow standard Odin formatting (use `odin fmt` when available)
- Use descriptive variable and function names
- Document procedures with comments
- Handle errors using the error handling system

### TypeScript/Angular

- Use TypeScript strict mode
- Follow Angular best practices
- Use descriptive component and service names
- Keep components focused and small

### Bash Scripts

- Use `shellcheck` to validate scripts
- Quote all variables and paths
- Use descriptive function and variable names

## Testing

### Running Tests

```bash
# Run all tests
./run.sh --test

# Run backend (Odin) tests only
cd tests
odin run di_tests.odin -file
odin run errors_tests.odin -file
odin run utils_tests.odin -file

# Run frontend tests only
cd frontend
bun test
```

### Adding Tests

When adding new functionality:

1. Add tests for new Odin code in the `tests/` directory
2. Add tests for new TypeScript code in `frontend/src/`
3. Ensure all tests pass before submitting a PR

## Pull Request Process

1. **Create a branch**: From the `main` branch, create your feature/fix branch
2. **Make changes**: Implement your changes following the code style guidelines
3. **Run tests**: Ensure all tests pass locally
4. **Update documentation**: Update README and other docs as needed
5. **Commit changes**: Use clear commit messages following conventional commits
6. **Push to your fork**: `git push origin feature/your-feature`
7. **Create PR**: Open a pull request against the `main` branch

### PR Description Template

```markdown
## Summary
Brief description of changes

## Changes Made
- [ ] List of changes
- [ ] List of changes

## Testing
- [ ] Tests pass locally
- [ ] Manual testing performed

## Related Issues
Fixes #issue-number (if applicable)
```

## Communication

### GitHub Issues

- Use [GitHub Issues](https://github.com/anomalyco/starter-odin-webui-angular-rspack/issues) for bug reports and feature requests
- Search existing issues before creating new ones
- Provide detailed information in bug reports

### Discussions

- Use [GitHub Discussions](https://github.com/anomalyco/starter-odin-webui-angular-rspack/discussions) for questions and community help
- Join the conversation to help other contributors

## Project Structure

```
starter-odin-webui-angular-rspack/
├── frontend/           # Angular + Rspack frontend
│   ├── src/
│   │   ├── app/        # Angular components
│   │   ├── core/       # Services (API, WebUI, etc.)
│   │   └── views/      # Page components
│   ├── package.json    # Frontend dependencies
│   └── angular.json    # Angular CLI config
│
├── src/                # Odin backend source
│   ├── lib/            # Libraries (DI, Events, Comms)
│   ├── services/       # Business services
│   └── core/           # Core application logic
│
├── tests/              # Test suite
│   ├── testing/        # Testing framework
│   └── *_tests.odin    # Test files
│
├── docs/               # Documentation
├── build/              # Build output (gitignored)
├── lib/                # External libraries (WebUI)
├── run.sh              # Build and run script
├── main.odin           # Application entry point
└── README.md           # Project documentation
```

## Recognition

Contributors will be recognized in the [Contributors](https://github.com/anomalyco/starter-odin-webui-angular-rspack/graphs/contributors) section of the repository.

## Questions?

Feel free to reach out through:
- GitHub Issues (for bugs/features)
- GitHub Discussions (for questions)
- Create a PR (for contributions)

Thank you for contributing! 🎉
