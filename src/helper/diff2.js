var Diff;

Diff = (function() {
  function Diff() {}

  Diff.DIFFERENCE_TYPES = {
    ADDED: 'added',
    DELETED: 'deleted',
    CHANGED: 'changed'
  };

  Diff.prototype.calculateDifferences = function(oldValue, newValue, key, path) {
    var newValueType, oldValueType, pathElement;
    if (key == null) {
      key = '';
    }
    if (path == null) {
      path = [];
    }
    newValueType = this._getType(newValue);
    oldValueType = this._getType(oldValue);
    if (key !== '') {
      pathElement = {
        key: key,
        valueType: newValueType
      };
      path = [].concat(path, [pathElement]);
    }
    if (typeof oldValue === 'function' || typeof newValue === 'function') {
      return [];
    } else if (!oldValue) {
      return [this._createDifference(Diff.DIFFERENCE_TYPES.ADDED, path, newValue)];
    } else if (!newValue) {
      return [this._createDifference(Diff.DIFFERENCE_TYPES.DELETED, path)];
    } else if (oldValueType !== newValueType) {
      return [this._createDifference(Diff.DIFFERENCE_TYPES.CHANGED, path, newValue)];
    } else if (typeof oldValue === 'object') {
      return this._getNestedDifferences(oldValue, newValue, key, path);
    } else if (newValue !== oldValue) {
      return [this._createDifference(Diff.DIFFERENCE_TYPES.CHANGED, path, newValue)];
    } else {
      return [];
    }
  };

  Diff.prototype._createDifference = function(type, path, value) {
    return {
      type: type,
      path: path,
      value: value
    };
  };

  Diff.prototype._getNestedDifferences = function(oldObject, newObject, key, path) {
    var allKeysToCheck, differences;
    if (key == null) {
      key = '';
    }
    if (path == null) {
      path = [];
    }
    allKeysToCheck = this._union(Object.keys(oldObject), Object.keys(newObject));
    differences = allKeysToCheck.map((function(_this) {
      return function(key) {
        return _this.calculateDifferences(oldObject[key], newObject[key], key, path);
      };
    })(this));
    return this._flatten(differences);
  };

  Diff.prototype._union = function(array1, array2) {
    return array1.concat(array2.filter(function(value) {
      return array1.indexOf(value) === -1;
    }));
  };

  Diff.prototype._flatten = function(arrayOfArrays) {
    return arrayOfArrays.reduce((function(prev, current) {
      return prev.concat(current);
    }), []);
  };

  Diff.prototype._getType = function(input) {
    var type;
    type = typeof input;
    if (type === 'object' && this._isArray(input)) {
      return 'array';
    } else {
      return type;
    }
  };

  Diff.prototype._isArray = function(input) {
    return {}.toString.call(input) === "[object Array]";
  };

  Diff.prototype.applyDifferences = function(object, originalDifferences) {
    var differences;
    differences = this._clone(originalDifferences);
    differences.forEach((function(_this) {
      return function(difference) {
        var lastKey, lastReference;
        lastKey = difference.path.pop().key;
        lastReference = difference.path.reduce(function(object, pathElement) {
          if (!object[pathElement.key]) {
            _this._createValue(object, pathElement.key, pathElement.valueType);
          }
          return object[pathElement.key];
        }, object);
        if (difference.type === Diff.DIFFERENCE_TYPES.CHANGED || difference.type === Diff.DIFFERENCE_TYPES.ADDED) {
          return lastReference[lastKey] = difference.value;
        } else {
          return delete lastReference[lastKey];
        }
      };
    })(this));
    return object;
  };

  Diff.prototype._createValue = function(object, key, type) {
    return object[key] = this._createFromType(type);
  };

  Diff.prototype._createFromType = function(type) {
    if (type === 'object') {
      return {};
    }
    if (type === 'array') {
      return [];
    }
  };

  Diff.prototype._clone = function(input) {
    var output;
    output = null;
    if (typeof input === 'object') {
      output = this._createFromType(this._getType(input));
      Object.keys(input).forEach((function(_this) {
        return function(key) {
          return output[key] = _this._clone(input[key]);
        };
      })(this));
    } else {
      output = input;
    }
    return output;
  };

  return Diff;

})();

module.exports = new Diff;
