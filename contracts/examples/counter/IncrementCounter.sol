// Copyright (c) 2017 Aler Denisov

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.4.18;

import "./ICounter.sol";
import "../../base/UIntStorage.sol";

/// @title Incremental implementation of counter for explanation external storage pattern
/// @author Aler Denisov
contract IncrementCounter is ICounter, Ownable {
  /// @notice Method modifier to ensure providen storage is UIntStorage
  /// @param _storage Instance of uint storage of counter
  /// @dev Throw error if storage isn't valid
  modifier validStorage(address _storage) {
    require(validateStorage(_storage));
    _;
  }

  /// @notice Increment counter on one tick each time when endpoint call incrementCounter via interface
  /// @param _storage Instance of uint storage of counter
  /// @dev Implementation of Counter interface 
  /// @return Current value of counter (after increment)
  function increaseCounter(address _storage) onlyOwner validStorage(_storage) public returns (uint) {
    UIntStorage counter = UIntStorage(_storage);
    require(counter.isUIntStorage());
    return counter.setValue(counter.getValue() + 1);
  }

  /// @notice Import stored value from external storage
  /// @param _storage Instance of uint storage of counter
  /// @return Current value of counter 
  function getCounter(address _storage) validStorage(_storage) public view returns (uint) {
    UIntStorage counter = UIntStorage(_storage);
    require(counter.isUIntStorage());
    return counter.getValue();
  }

  /// @notice Method to validate received storage
  /// @param _storage Instance of uint storage of counter
  /// @return True if storage is valid, false\revert overwise
  function validateStorage(address _storage) public view returns (bool) {
    return UIntStorage(_storage).isUIntStorage();
  }

  /// @notice Method to transfer ownership of storage to another counter
  /// @param _storage Instance of uint storage of counter
  /// @param _counter Instance of ICounter implementation to transfer ownership
  /// @return True if ownership is transfered, false\revert overwise
  function transferStorage(address _storage, address _counter) onlyOwner validStorage(_storage) public returns (bool) {
    UIntStorage(_storage).transferOwnership(_counter);
    return true;
  }
}