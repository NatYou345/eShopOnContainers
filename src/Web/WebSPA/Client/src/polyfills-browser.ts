// Browser polyfills for Node.js modules
(window as any).global = window;
(window as any).process = {
  env: { DEBUG: undefined },
  version: ''
};
(window as any).Buffer = (window as any).Buffer || require('buffer').Buffer;
