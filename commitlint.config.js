/* eslint-disable no-undef */
module.exports = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "type-enum": [
      2,
      "always",
      [
        "build",
        "chore",
        "ci",
        "docs",
        "feat",
        "fix",
        "perf",
        "refactor",
        "revert",
        "style",
        "test"
      ]
    ],
    "scope-min-length": [2, "always", 6],
    "subject-min-length": [2, "always", 10],
    "body-empty": [1, "never"],
    "body-min-length": [1, "always", 20],
    "body-leading-blank": [1, "always"],
    "footer-leading-blank": [1, "always"]
  }
};
/* eslint-enable no-undef */
