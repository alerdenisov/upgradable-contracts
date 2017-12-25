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
contract IncrementCounter is ICounter {
  /// @notice Instance of uint storage to store current counter value
  /// @dev Should be valid instance of storage
  UIntStorage public counter;

  /// @notice Constructor of incremental counter
  /// @param _storage The address of uint storage which should store counter value
  function IncrementCounter(address _storage) public {
    counter = UIntStorage(_storage);
  }

  /// @notice Increment counter on one tick each time when endpoint call incrementCounter via interface
  /// @dev Implementation of Counter interface 
  /// @return Current value of counter (after increment)
  function increaseCounter() public returns (uint) {
    return counter.setValue(getCounter() + 1);
  }

  /// @notice Import stored value from external storage
  /// @return Current value of counter 
  function getCounter() public view returns (uint) {
    return counter.getValue();
  }
}