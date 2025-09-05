import js from '@eslint/js';
import importPlugin from 'eslint-plugin-import';
import jsonc from 'eslint-plugin-jsonc';
import prettier from 'eslint-plugin-prettier';
import yml from 'eslint-plugin-yml';
import jsoncParser from 'jsonc-eslint-parser';
import yamlParser from 'yaml-eslint-parser';

export default [
  // Base configuration
  js.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        browser: true,
        es2021: true,
        node: true,
        jest: true,
        vitest: true,
        cypress: true,
      },
    },
    plugins: {
      import: importPlugin,
      prettier,
    },
    rules: {
      // Prettier integration
      'prettier/prettier': 'error',

      // Import rules
      'import/order': [
        'error',
        {
          groups: ['builtin', 'external', 'internal', 'parent', 'sibling', 'index'],
          'newlines-between': 'always',
          alphabetize: { order: 'asc', caseInsensitive: true },
        },
      ],
      'import/no-unresolved': 'error',
      'import/no-duplicates': 'error',
      'import/no-unused-modules': 'warn',

      // General code quality
      'no-console': 'warn',
      'no-debugger': 'error',
      'no-unused-vars': 'warn',
      'no-var': 'error',
      'prefer-const': 'error',
      eqeqeq: ['error', 'always'],
    },
  },

  // YAML files
  {
    files: ['**/*.yml', '**/*.yaml'],
    languageOptions: {
      parser: yamlParser,
    },
    plugins: {
      yml,
    },
    rules: {
      ...yml.configs.standard.rules,
    },
  },

  // JSON files
  {
    files: ['**/*.json', '**/*.jsonc'],
    languageOptions: {
      parser: jsoncParser,
    },
    plugins: {
      jsonc,
    },
    rules: {
      ...jsonc.configs['recommended-with-json'].rules,
    },
  },

  // Ignore patterns
  {
    ignores: [
      'node_modules/**',
      'dist/**',
      'build/**',
      'out/**',
      'coverage/**',
      '.next/**',
      'vite-test-project/**',
      'mcp-servers/**',
      '.github/workflows/**',
      '**/*.md',
      '**/*.mdx',
      '**/*.ts',
      '**/*.tsx',
    ],
  },
];
