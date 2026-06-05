// Conventional Commits para o Stem Player.
// Scopes alinhados à arquitetura e aos módulos de stem-core.
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      ['feat', 'fix', 'refactor', 'perf', 'test', 'docs', 'style', 'build', 'ci', 'chore', 'revert'],
    ],
    'scope-enum': [
      2,
      'always',
      [
        'core', 'loops', 'session', 'audio', 'import', 'persistence', 'separation',
        'tauri', 'ui', 'ipc', 'openspec', 'harness', 'deps', 'release',
      ],
    ],
    'scope-empty': [0],
    'subject-case': [2, 'always', 'lower-case'],
    'subject-full-stop': [2, 'never', '.'],
    'header-max-length': [2, 'always', 72],
  },
};
