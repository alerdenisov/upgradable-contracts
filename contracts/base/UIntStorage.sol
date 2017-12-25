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


/// @title Plain uint storage for external usage 
/// @author Aler Denisov
contract UIntStorage {
  /// @notice Private store point of uint type value
  uint private value;

  /// @notice External method to store new value
  /// @dev Storage didn't fire any events. Ensure your external contract did that if events is required.
  /// @return Stored value in storage (after change)
  function setValue(uint _value) external returns (uint) {
    value = _value;
    return value;
  }

  /// @notice Send stored value to external contract
  /// @return Current value in storage
  function getValue() external view returns (uint) {
    return value;
  }
}