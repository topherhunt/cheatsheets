module.exports = {
  "env": {
    "browser": true,
    "es6": true
  },
  "extends": [
    "eslint:recommended",
    "plugin:react/recommended"
  ],
  "settings": {
    "react": {"version": "detect"}
  },
  "globals": {
    "Atomics": "readonly",
    "SharedArrayBuffer": "readonly"
  },
  "parser": "babel-eslint",
  "rules": {
    // These are in addition to the eslint:recommended and react/recommended rules
    "default-case": "error",
    "eqeqeq": "error",
    "require-unicode-regexp": "error",
    "arrow-parens": "error",
    "no-duplicate-imports": "error",
    "no-var": "error"
  }
};
