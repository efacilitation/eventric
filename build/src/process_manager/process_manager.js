
/**
* @name ProcessManager
* @module ProcessManager
* @description
*
* ProcessManagers can handle multiple DomainEvents and have correlation and causation features
 */
var ProcessManagerService;

ProcessManagerService = (function() {
  function ProcessManagerService() {
    this._processManagerInstances = {};
  }


  /**
  * @name add
  * @module ProcessManager
  * @description Add a ProcessManager
  *
  * @param {String} processManagerName Name of the ProcessManager
  * @param {Object} processManagerObject Object containing the ProcessManagerDefinition
   */

  ProcessManagerService.prototype.add = function(processManagerName, processManagerObj, index) {
    var contextName, domainEventName, domainEventNames, _ref, _results;
    _ref = processManagerObj.initializeWhen;
    _results = [];
    for (contextName in _ref) {
      domainEventNames = _ref[contextName];
      _results.push((function() {
        var _i, _len, _results1;
        _results1 = [];
        for (_i = 0, _len = domainEventNames.length; _i < _len; _i++) {
          domainEventName = domainEventNames[_i];
          _results1.push(index.subscribeToDomainEvent(contextName, domainEventName, (function(_this) {
            return function(domainEvent) {
              return _this._spawnProcessManager(processManagerName, processManagerObj["class"], contextName, domainEvent, index);
            };
          })(this)));
        }
        return _results1;
      }).call(this));
    }
    return _results;
  };

  ProcessManagerService.prototype._spawnProcessManager = function(processManagerName, ProcessManagerClass, contextName, domainEvent, index) {
    var handleContextDomainEventNames, key, processManager, processManagerId, value, _base, _base1;
    processManagerId = index.generateUid();
    processManager = new ProcessManagerClass;
    processManager.$endProcess = (function(_this) {
      return function() {
        return _this._endProcessManager(processManagerName, processManagerId);
      };
    })(this);
    handleContextDomainEventNames = [];
    for (key in processManager) {
      value = processManager[key];
      if ((key.indexOf('from')) === 0 && (typeof value === 'function')) {
        handleContextDomainEventNames.push(key);
      }
    }
    this._subscribeProcessManagerToDomainEvents(processManager, handleContextDomainEventNames, index);
    processManager.initialize(domainEvent);
    if ((_base = this._processManagerInstances)[processManagerName] == null) {
      _base[processManagerName] = {};
    }
    if ((_base1 = this._processManagerInstances[processManagerName])[processManagerId] == null) {
      _base1[processManagerId] = {};
    }
    return this._processManagerInstances[processManagerName][processManagerId] = processManager;
  };

  ProcessManagerService.prototype._endProcessManager = function(processManagerName, processManagerId) {
    return delete this._processManagerInstances[processManagerName][processManagerId];
  };

  ProcessManagerService.prototype._subscribeProcessManagerToDomainEvents = function(processManager, handleContextDomainEventNames, index) {
    return index.subscribeToDomainEvent((function(_this) {
      return function(domainEvent) {
        var handleContextDomainEventName, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = handleContextDomainEventNames.length; _i < _len; _i++) {
          handleContextDomainEventName = handleContextDomainEventNames[_i];
          if (("from" + domainEvent.context + "_handle" + domainEvent.name) === handleContextDomainEventName) {
            _results.push(_this._applyDomainEventToProcessManager(handleContextDomainEventName, domainEvent, processManager));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      };
    })(this));
  };

  ProcessManagerService.prototype._applyDomainEventToProcessManager = function(handleContextDomainEventName, domainEvent, processManager) {
    var err;
    if (!processManager[handleContextDomainEventName]) {
      return err = new Error("Tried to apply DomainEvent '" + domainEventName + "' to Projection without a matching handle method");
    } else {
      return processManager[handleContextDomainEventName](domainEvent);
    }
  };

  return ProcessManagerService;

})();

module.exports = new ProcessManagerService;
