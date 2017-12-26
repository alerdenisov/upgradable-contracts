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

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./ICounter.sol";
import "../../base/UIntStorage.sol";

/// @title Counter controller provides methods to update implementation of ICounter
/// @author Aler Denisov
contract CounterController is Ownable {
  /// @notice Instance of counter storage
  /// @dev Field is constant to ensure users to immutability and non-changable storage
  UIntStorage public store = new UIntStorage();

  /// @notice Current implementation of ICounter
  /// @dev Field is public, but could be a private. It's public just for case if user want to check current implementation before execute
  ICounter public counter;

  /// @notice Counter implementation update event
  /// @dev Fires each time when controller update couter to new version
  event CounterUpdate(address previousCounter, address nextCounter);

  /// @notice Permissioned method to update implementation
  /// @dev Ensure you didn't forget to transfer ownership of implementation to current controller
  function updateCounter(address _counter) 
    onlyOwner
    public returns (bool) 
  {
    if (address(counter) != 0x0) {
      counter.transferStorage(store, _counter);
    } else {
      store.transferOwnership(_counter);
    }

    CounterUpdate(counter, _counter);
    counter = ICounter(_counter);
  }

  /// @notice External (users) endpoint to execute corresponding method inside implementation
  function increaseCounter() public returns (uint) {
    return counter.increaseCounter(store);
  }

  /// @notice Eject current value from implentation
  /// @dev Doesn't call storage directly to allow implementation handle read in custom way
  function getCounter() public view returns (uint) {
    return counter.getCounter(store);
  }
}