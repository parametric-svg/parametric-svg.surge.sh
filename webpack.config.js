const WebpackShellPlugin = require('webpack-shell-plugin');

const directories =
  names => new RegExp(`(?:^|/)(?:${names.join('|')})/`);

const extensions =
  names => new RegExp(`\\.(?:${names.join('|')})$`);

module.exports = {
  plugins: [
    new WebpackShellPlugin({
      beforeBuildStart: [
        './scripts/styles',
      ],
    }),
  ],

  entry: './source/index.js',

  output: {
    path: './public',
    filename: 'index.[hash].js',
  },

  module: {
    loaders: [
      {
        test: extensions(['elm']),
        exclude: directories(['elm-stuff', 'node_modules']),
        loader: `elm-webpack?${[
          'warn',
          'pathToMake=node_modules/.bin/elm-make',
        ].join('&')}`,
      },

      {
        test: extensions(['css']),
        loader: 'raw-loader',
      },
    ],

    noParse: extensions(['elm', 'css']),
  },
};
