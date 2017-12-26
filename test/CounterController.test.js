import expectThrow from './utils/expectThrow'

const IncrementCounter = artifacts.require('./IncrementCounter.sol')
const IncrementCounterPhaseTwo = artifacts.require('./IncrementCounterPhaseTwo.sol')
const MultiplyCounterPhaseThree = artifacts.require('./MultiplyCounterPhaseThree.sol')
const CounterController = artifacts.require('./CounterController.sol')
const UIntStorage = artifacts.require('./UIntStorage.sol')

contract('CounterController', ([owner, user]) => {
  let controller, counterOne, counterTwo, counterThree, storage

  before(async () => {
    controller = await CounterController.new()
    storage = UIntStorage.at(await controller.store())
    counterOne = await IncrementCounter.new()
    counterTwo = await IncrementCounterPhaseTwo.new()
    counterThree = await MultiplyCounterPhaseThree.new()

    await counterOne.transferOwnership(controller.address)
    await counterTwo.transferOwnership(controller.address)
    await counterThree.transferOwnership(controller.address)
  })

  it('Shoult create storage', async () => {
    assert(await storage.isUIntStorage(), 'Controller doesn\'t create proper storage')
  })

  it('Should change counter implementation', async () => {
    await controller.updateCounter(counterOne.address)
    assert(await controller.counter() === counterOne.address, `Unxpected counter in controller (${await controller.counter()} but expect ${counterOne.address})`)
  })

  it('Should increase counter on 1', async () => {
    await controller.increaseCounter()
    const value = await controller.getCounter()
    assert(value.eq(1), `Unxpected counter value: ${value.toString(10)}`)
  })

  it('Should update counter', async () => {
    await controller.updateCounter(counterTwo.address)
    assert(await controller.counter() === counterTwo.address, `Unxpected counter in controller (${await controller.counter()} but expect ${counterTwo.address})`)
  })
  
  it('Should increase counter on 10 after update', async () => {
    await controller.increaseCounter()
    const value = await controller.getCounter()
    assert(value.eq(11), `Unxpected counter value: ${value.toString(10)}`)
  })

  it('Should reject non-authenticated update', async () => {
    await expectThrow(controller.updateCounter(counterTwo.address, { from: user }))
  })
  
  it('Should update on phase three and increase counter to 11*11 after execution', async () => {
    await controller.updateCounter(counterThree.address)
    await controller.increaseCounter()
    const value = await controller.getCounter()
    assert(value.eq(121), `Unxpected counter value: ${value.toString(10)}`)
  })
})
