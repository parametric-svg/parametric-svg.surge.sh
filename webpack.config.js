const directoryRE = (dirname) => new RegExp(`(?:^|/)${dirname}/`);

module.exports = {
  entry: './source/index.js',

  output: {
    path: './public',
    filename: 'scripts.js',
  },

  module: {
    loaders: [{
      test: /\.elm$/,
      exclude: ['elm-stuff', 'node_modules'].map(directoryRE),
      loader: 'elm-webpack?warn&pathToMake=node_modules/.bin/elm-make',
    }],

    noParse: /\.elm$/,
  },
};
