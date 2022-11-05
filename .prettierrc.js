module.exports = {
  singleQuote: true,
  bracketSpacing: true,
  printWidth: 80,
  overrides: [
    {
      files: '*.sol',
      options: {
        printWidth: 80,
        tabWidth: 4,
        singleQuote: false,
        explicitTypes: 'always',
      },
    },
  ],
  plugins: [require.resolve('prettier-plugin-solidity')],
};
