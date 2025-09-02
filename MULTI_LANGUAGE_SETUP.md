# Multi-Language Support Guide

This guide covers the comprehensive multi-language support for JavaScript/TypeScript, Python, Java, C++, and SQL in the Watchdog system.

## Supported Languages & Tools

| Language | Linter | Formatter | Security | Type Checker |
|----------|--------|-----------|----------|--------------|
| **JavaScript/TypeScript** | ESLint | Prettier | - | TypeScript |
| **Python** | Flake8 | Black + isort | Bandit + Safety | MyPy |
| **Java** | Checkstyle | Google Java Format | - | javac |
| **C++** | Clang-Tidy | Clang-Format | - | - |
| **SQL** | SQLFluff | SQLFluff | - | - |

## Quick Start

### 1. Install Dependencies

The GitHub Actions workflow automatically installs all required tools. For local development:

```bash
# Node.js dependencies
npm install

# Python tools
pip install flake8 black isort mypy bandit safety

# Java tools (download automatically in workflow)
# C++ tools (install via package manager)
sudo apt-get install clang-format clang-tidy  # Ubuntu/Debian
brew install clang-format llvm               # macOS

# SQL tools
pip install sqlfluff
```

### 2. Run Multi-Language Linting

```bash
# All languages
npm run lint

# Individual languages
npm run lint:js      # JavaScript/TypeScript
npm run lint:python  # Python
npm run lint:java    # Java
npm run lint:cpp     # C++
npm run lint:sql     # SQL
```

### 3. Run Multi-Language Formatting

```bash
# All languages
npm run format

# Individual languages
npm run format:js      # JavaScript/TypeScript
npm run format:python  # Python
npm run format:java    # Java
npm run format:cpp     # C++
npm run format:sql     # SQL
```

## Configuration Files

### Python Configuration

**`.flake8`** - Python linting configuration:
```ini
[flake8]
max-line-length = 100
extend-ignore = E203,W503,E501
exclude = .git,__pycache__,.venv,build,dist
max-complexity = 10
```

**`pyproject.toml`** - Black, isort, mypy configuration:
```toml
[tool.black]
line-length = 100
target-version = ['py38', 'py39', 'py310', 'py311']

[tool.isort]
profile = "black"
line_length = 100

[tool.mypy]
python_version = "3.8"
warn_return_any = true
disallow_untyped_defs = true
```

### Java Configuration

**`checkstyle.xml`** - Java linting rules based on Google Style Guide:
- Line length: 120 characters
- Indentation: 2 spaces
- Naming conventions enforced
- Import organization
- Javadoc requirements for public methods

### C++ Configuration

**`.clang-format`** - C++ formatting based on Google Style:
```yaml
BasedOnStyle: Google
IndentWidth: 2
ColumnLimit: 100
PointerAlignment: Left
```

**`.clang-tidy`** - C++ linting rules:
- Comprehensive checks enabled
- Google naming conventions
- Modern C++ best practices
- Performance and readability rules

### SQL Configuration

**`.sqlfluff`** - SQL linting and formatting:
```ini
[sqlfluff]
dialect = postgres
rules = all
exclude_rules = L034,L036,L044

[sqlfluff:indentation]
indent_unit = space
tab_space_size = 2
```

## Language-Specific Features

### JavaScript/TypeScript
- **ESLint**: Comprehensive rules for React, Next.js, Node.js
- **Prettier**: Universal formatting with file-type overrides
- **TypeScript**: Strict type checking with path mapping
- **Import sorting**: Automatic import organization

### Python
- **Flake8**: PEP 8 compliance with custom extensions
- **Black**: Uncompromising code formatter
- **isort**: Import sorting compatible with Black
- **MyPy**: Static type checking
- **Bandit**: Security vulnerability scanning
- **Safety**: Dependency vulnerability checking

### Java
- **Checkstyle**: Google Java Style Guide enforcement
- **Google Java Format**: Consistent code formatting
- **Import organization**: Automatic import sorting
- **Javadoc validation**: Documentation completeness

### C++
- **Clang-Tidy**: Comprehensive static analysis
- **Clang-Format**: Google C++ style formatting
- **Modern C++**: C++11/14/17/20 best practices
- **Performance checks**: Optimization recommendations

### SQL
- **SQLFluff**: Multi-dialect SQL linting
- **Formatting**: Consistent SQL style
- **Templating**: Jinja template support
- **Dialect support**: PostgreSQL, MySQL, SQLite, etc.

## Workflow Integration

### GitHub Actions Steps

1. **Setup**: Install all language tools and runtimes
2. **Lint Check**: Run linting for all languages
3. **Format Check**: Verify formatting compliance
4. **Auto-fix**: Automatically fix issues where possible
5. **Security**: Run security scans (Python)
6. **Commit**: Push fixes back to PR branch

### Parallel Execution

The workflow runs language checks in parallel where possible:
- Node.js and Python setup run simultaneously
- Linting checks run in sequence but quickly
- Security scans run independently

### Error Handling

- Individual language failures don't stop the entire workflow
- `continue-on-error: true` for graceful degradation
- Comprehensive reporting of all issues found

## File Type Support

| Extension | Language | Tools Applied |
|-----------|----------|---------------|
| `.js`, `.jsx` | JavaScript | ESLint, Prettier |
| `.ts`, `.tsx` | TypeScript | ESLint, Prettier, TSC |
| `.py` | Python | Flake8, Black, isort, MyPy, Bandit |
| `.java` | Java | Checkstyle, Google Java Format |
| `.cpp`, `.hpp`, `.c`, `.h` | C++ | Clang-Tidy, Clang-Format |
| `.sql` | SQL | SQLFluff |
| `.json`, `.yaml`, `.md` | Data/Docs | Prettier, ESLint |

## Project Structure Examples

### Full-Stack Project
```
project/
├── frontend/           # React/TypeScript
│   ├── src/
│   └── package.json
├── backend/           # Python FastAPI
│   ├── app/
│   └── requirements.txt
├── mobile/           # Java Android
│   └── src/main/java/
├── database/         # SQL migrations
│   └── migrations/
└── native/          # C++ library
    └── src/
```

### Configuration Priority
1. **Language-specific configs** take precedence
2. **Global configs** apply to all files
3. **Override patterns** for special cases

## Advanced Configuration

### Custom Rules

Add project-specific rules to any configuration file:

```python
# Python - Custom flake8 rules
[flake8]
per-file-ignores = 
    tests/*:S101  # Allow assert in tests
    __init__.py:F401  # Allow unused imports
```

```xml
<!-- Java - Custom Checkstyle rules -->
<module name="LineLength">
    <property name="max" value="120"/>
    <property name="ignorePattern" value="^import.*"/>
</module>
```

### Environment-Specific Settings

Different rules for different environments:
- **Development**: More lenient rules
- **Production**: Stricter enforcement
- **Testing**: Special allowances

### IDE Integration

Most IDEs support these configurations:
- **VSCode**: Extensions for each language
- **IntelliJ**: Built-in support for Java, plugins for others
- **Vim/Neovim**: Language server protocol support
- **Emacs**: Major modes for each language

## Troubleshooting

### Common Issues

**Python tools not found:**
```bash
# Ensure Python tools are in PATH
pip install --user flake8 black isort
export PATH=$PATH:~/.local/bin
```

**Java tools missing:**
```bash
# Download tools manually if needed
wget https://github.com/checkstyle/checkstyle/releases/latest/download/checkstyle-*-all.jar
```

**C++ tools unavailable:**
```bash
# Install LLVM/Clang suite
sudo apt-get install llvm clang clang-tools
```

**SQL dialect issues:**
```ini
# Specify correct dialect in .sqlfluff
[sqlfluff]
dialect = mysql  # or postgres, sqlite, etc.
```

### Performance Optimization

**Large repositories:**
- Use `.gitignore` patterns to exclude build artifacts
- Configure tool-specific ignore files
- Run tools on changed files only in development

**Slow workflows:**
- Enable caching for all package managers
- Use parallel job execution
- Skip tools for languages not present in repository

### Custom Integration

**Add new languages:**
1. Add linting/formatting commands to `package.json`
2. Update GitHub Actions workflow
3. Add configuration files
4. Update ignore patterns

**Modify existing rules:**
1. Edit configuration files
2. Test locally before committing
3. Document changes in project README

## Metrics and Reporting

### Code Quality Metrics
- Lines of code per language
- Linting errors/warnings trends
- Code coverage (where applicable)
- Security vulnerability counts

### Workflow Metrics
- Average workflow execution time
- Success/failure rates per language
- Most common issues found
- Auto-fix success rates

## Security Considerations

### Python Security
- **Bandit**: Scans for common security issues
- **Safety**: Checks dependencies for known vulnerabilities
- **Dependency pinning**: Lock file verification

### General Security
- **Secrets scanning**: No hardcoded credentials
- **Dependency updates**: Regular security updates
- **Access control**: Minimal required permissions

---

## Language-Specific Resources

### JavaScript/TypeScript
- [ESLint Rules](https://eslint.org/docs/rules/)
- [Prettier Configuration](https://prettier.io/docs/en/configuration.html)
- [TypeScript Compiler Options](https://www.typescriptlang.org/tsconfig)

### Python
- [Flake8 Documentation](https://flake8.pycqa.org/)
- [Black Code Style](https://black.readthedocs.io/)
- [MyPy Type Checking](https://mypy.readthedocs.io/)

### Java
- [Checkstyle Checks](https://checkstyle.sourceforge.io/checks.html)
- [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html)

### C++
- [Clang-Tidy Checks](https://clang.llvm.org/extra/clang-tidy/checks/list.html)
- [Clang-Format Options](https://clang.llvm.org/docs/ClangFormatStyleOptions.html)
- [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html)

### SQL
- [SQLFluff Rules](https://docs.sqlfluff.com/en/stable/rules.html)
- [SQL Style Guide](https://www.sqlstyle.guide/)

This multi-language setup provides comprehensive code quality assurance across your entire technology stack while maintaining consistency and best practices for each language.
