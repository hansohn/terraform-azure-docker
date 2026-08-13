# Contributing to terraform-azure-docker

Thank you for your interest in contributing to terraform-azure-docker! This document provides guidelines and instructions for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

This project adheres to a [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to [conduct@hansohn.io](mailto:conduct@hansohn.io).

## Getting Started

Before you begin contributing, please:

1. Read the [README.md](../README.md) to understand the project
2. Check existing [issues](https://github.com/hansohn/terraform-azure-docker/issues) and [pull requests](https://github.com/hansohn/terraform-azure-docker/pulls)
3. Join discussions in [GitHub Discussions](https://github.com/hansohn/terraform-azure-docker/discussions) if you have questions

## Development Setup

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed and running
- [Make](https://www.gnu.org/software/make/) installed
- [Git](https://git-scm.com/) for version control
- `curl` and `jq` (used to resolve the latest tool versions for ad-hoc builds)

### Local Development

1. **Fork and clone the repository:**
   ```bash
   git clone https://github.com/YOUR-USERNAME/terraform-azure-docker.git
   cd terraform-azure-docker
   ```

2. **Build the Docker image locally:**
   ```bash
   make docker/build
   ```

3. **Lint the Dockerfile:**
   ```bash
   make docker/lint
   ```

4. **Run the image locally:**
   ```bash
   make docker/run
   ```

## How to Contribute

### Types of Contributions

We welcome various types of contributions:

- **Bug fixes**: Fix issues or unexpected behavior
- **Feature additions**: Add new utilities or capabilities
- **Documentation improvements**: Enhance or clarify documentation
- **CI/CD improvements**: Optimize workflows and automation
- **Testing**: Add or improve test coverage

### Workflow

1. Create a new branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes following our [coding standards](#coding-standards)

3. Test your changes locally:
   ```bash
   make docker/lint
   make docker/build
   make docker/run
   ```

4. Commit your changes with clear, descriptive messages:
   ```bash
   git commit -m "Add feature: description of changes"
   ```

5. Push to your fork and submit a pull request

## Coding Standards

### Dockerfile Best Practices

- Pin versions for all installed packages when possible
- Use multi-stage builds to minimize image size
- Follow [Docker best practices](https://docs.docker.com/develop/dev-best-practices/)
- Add comments to explain complex commands
- Group related commands using `&&` to reduce layers

### Makefile Conventions

- Use descriptive target names
- Add comments for complex targets
- Include help text using `## Help text` format
- Maintain consistent formatting and indentation

### GitHub Actions Workflows

- Use specific action versions (avoid `@latest` or `@master`)
- Add timeout protection to jobs
- Include descriptive job and step names
- Use caching where appropriate

## Testing

### Local Testing

Before submitting a PR, ensure:

1. **Dockerfile passes linting:**
   ```bash
   make docker/lint
   ```

2. **Image builds successfully:**
   ```bash
   make docker/build
   ```

3. **All utilities are accessible:**
   ```bash
   make docker/run
   # Inside container:
   terraform version
   terragrunt --version
   terraform-docs --version
   tflint --version
   trivy --version
   az version
   ```

4. **Check for security vulnerabilities** (if possible)

### CI/CD Testing

All pull requests automatically run:
- Dockerfile linting
- Multi-platform builds (linux/amd64, linux/arm64), with provenance attestations and SBOM generation

Published images (on tagged releases and scheduled refreshes) additionally get:
- A Trivy vulnerability scan of the pushed image

## Pull Request Process

1. **Before submitting:**
   - Ensure your code follows the coding standards
   - Test your changes locally
   - Update documentation if needed
   - Add yourself to contributors if this is your first contribution

2. **PR Title and Description:**
   - Use clear, descriptive titles
   - Follow the PR template structure (what, why, references)
   - Link related issues using `closes #123` or `relates to #456`

3. **PR Checklist:**
   - [ ] My code follows the project's style guidelines
   - [ ] I have tested my changes locally
   - [ ] I have updated documentation if needed
   - [ ] All CI checks are passing
   - [ ] I have added comments to complex code sections

4. **Review Process:**
   - Maintainers will review your PR
   - Address any feedback or requested changes
   - Once approved, a maintainer will merge your PR

5. **After Merge:**
   - Your changes will be included in the next scheduled build
   - Images are refreshed every Monday at 7am UTC

## Reporting Issues

### Bug Reports

Use the [Bug Report template](ISSUE_TEMPLATE/bug-report.yml) and include:
- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, Docker version, image tag)
- Relevant logs or error messages

### Feature Requests

Use the [Feature Request template](ISSUE_TEMPLATE/feature-request.yml) and describe:
- The problem or use case
- Proposed solution
- Alternative approaches considered
- Additional context or examples

### Support Requests

Use the [Support Request template](ISSUE_TEMPLATE/support-request.yml) for:
- Questions about usage
- Help with configuration
- General inquiries

## Security

If you discover a security vulnerability, please follow our [Security Policy](SECURITY.md) and report it to [security@hansohn.io](mailto:security@hansohn.io). Do not create a public issue.

## License

By contributing to this project, you agree that your contributions will be licensed under the same license as the project (see [LICENSE](../LICENSE)).

## Questions?

- Open a [Discussion](https://github.com/hansohn/terraform-azure-docker/discussions)
- Check existing [Issues](https://github.com/hansohn/terraform-azure-docker/issues)
- Review the [README](../README.md)

Thank you for contributing! 🎉
