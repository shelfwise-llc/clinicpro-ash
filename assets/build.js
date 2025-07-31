const esbuild = require('esbuild');
const path = require('path');
const fs = require('fs');

// Define build options
const opts = {
  entryPoints: ['js/app.js'],
  bundle: true,
  outdir: '../priv/static/assets',
  sourcemap: 'linked',
  minify: process.env.NODE_ENV === 'production',
  target: 'esnext',
  loader: {
    '.js': 'jsx',
    '.png': 'file',
    '.jpg': 'file',
    '.svg': 'file',
    '.woff': 'file',
    '.woff2': 'file',
    '.ttf': 'file',
    '.eot': 'file',
  },
  assetNames: '[name]-[hash]',
  chunkNames: '[name]-[hash]',
  format: 'esm',
  publicPath: '/assets',
  logLevel: 'info',
  define: {
    global: 'globalThis',
  },
  // Handle Phoenix dependencies by marking them as external or resolving them
  external: [
    'phoenix',
    'phoenix_html',
    'phoenix_live_view'
  ],
  // Set up path resolution for Phoenix dependencies
  resolveExtensions: ['.js', '.jsx', '.ts', '.tsx'],
};

// Watch mode for development
if (process.argv.includes('--watch')) {
  esbuild.context(opts).then((ctx) => {
    console.log('Watching for changes...');
    return ctx.watch();
  }).catch((error) => {
    console.error('Watch build failed:', error);
    process.exit(1);
  });
} else {
  // Run the build
  esbuild.build(opts).catch((error) => {
    console.error('Build failed:', error);
    process.exit(1);
  });
}
