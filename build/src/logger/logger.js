module.exports = {
  _logLevel: 1,
  setLogLevel: function(logLevel) {
    return this._logLevel = (function() {
      switch (logLevel) {
        case 'debug':
          return 0;
        case 'warn':
          return 1;
        case 'info':
          return 2;
        case 'error':
          return 3;
      }
    })();
  },
  debug: function() {
    if (this._logLevel > 0) {
      return;
    }
    return console.log.apply(console, arguments);
  },
  warn: function() {
    if (this._logLevel > 1) {
      return;
    }
    return console.log.apply(console, arguments);
  },
  info: function() {
    if (this._logLevel > 2) {
      return;
    }
    return console.log.apply(console, arguments);
  },
  error: function() {
    if (this._logLevel > 3) {
      return;
    }
    return console.log.apply(console, arguments);
  }
};
