const IncrementCounter = artifacts.require('./IncrementCounter.sol')
const UIntStorage = artifacts.require('./UIntStorage.sol')

contract('IncrementCounter', ([owner, user]) => {
  let counter, storage
  before(async () => {
    storage = await UIntStorage.new()
    counter = await IncrementCounter.new(storage.address)
  })

  it('Should receive 0 at begin', async () => {
    const currentValue = await counter.getCounter()
    assert(currentValue.eq(0), `Uxpected counter value: ${currentValue.toString(10)}`)
  })

  it('Should increase value on 1', async () => {
    await counter.increaseCounter()
    const newValue = await counter.getCounter()
    assert(newValue.eq(1), `Unxpected counter value: ${newValue.toString(10)}`)
  })

  it('Should store 1 after increment', async () => {
    const storedValue = await storage.getValue()
    assert(storedValue.eq(1), `Unxpected stored value: ${storedValue.toString(10)}`)
  })
})