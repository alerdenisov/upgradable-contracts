import expectThrow from './utils/expectThrow'

const IncrementCounter = artifacts.require('./IncrementCounter.sol')
const IncrementCounterPhaseTwo = artifacts.require('./IncrementCounterPhaseTwo.sol')
const UIntStorage = artifacts.require('./UIntStorage.sol')
const BoolStorage = artifacts.require('./BoolStorage.sol')

contract('IncrementCounter', ([owner, user]) => {
  let counter, storage, fakeStorage, secondCounter
  before(async () => {
    storage = await UIntStorage.new()
    fakeStorage = await BoolStorage.new()
    counter = await IncrementCounter.new()
    secondCounter = await IncrementCounterPhaseTwo.new()

    await storage.transferOwnership(counter.address)
  })

  it('Should receive 0 at begin', async () => {
    const currentValue = await counter.getCounter(storage.address)
    assert(currentValue.eq(0), `Uxpected counter value: ${currentValue.toString(10)}`)
  })

  it('Should increase value on 1', async () => {
    await counter.increaseCounter(storage.address)
    const newValue = await counter.getCounter(storage.address)
    assert(newValue.eq(1), `Unxpected counter value: ${newValue.toString(10)}`)
  })

  it('Should prevent non-authenticated write', async () => {
    await expectThrow(storage.setValue(100))
  })

  it('Should store 1 after increment', async () => {
    const storedValue = await storage.getValue()
    assert(storedValue.eq(1), `Unxpected stored value: ${storedValue.toString(10)}`)
  })

  it('Should validate storage', async () => {
    await counter.validateStorage(storage.address)
  })

  it('Should unvalidate fake storage', async () => {
    await expectThrow(counter.validateStorage(fakeStorage.address))
  })

  it('Should transfer ownership', async () => {
    await counter.transferStorage(storage.address, secondCounter.address);
  })

  it('Should reject increase from outdated counter', async () => {
    await expectThrow(counter.increaseCounter(storage.address));
  })

  it('Should increase counter with new logic', async () => {
    await secondCounter.increaseCounter(storage.address)
    const newValue = await secondCounter.getCounter(storage.address)
    assert(newValue.eq(11), `Unxpected counter value: ${newValue.toString(10)}`)
  })

  it('Should reject non-authenticated transfer storage', async () => {
    await expectThrow(secondCounter.transferStorage(storage.address, user, { from: user }))
  })

  it('Should reject increase from user fron previous test', async () => {
    await expectThrow(storage.setValue(100500, { from: user }))
  })

  it('Should store 11 as before', async () => {
    const storedValue = await storage.getValue()
    assert(storedValue.eq(11), `Unxpected stored value: ${storedValue.toString(10)}`)
  })
})