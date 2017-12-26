# Счетчик

Представим абстрактный оторванный от реальности пример – счетчик с обновляемой логикой увеличения.

* __Стадия 1__. С каждым вызовом счетчик увеличивается на 1
* __Стадия 2__. С каждым вызовом счетчик увеличивается на 10

При традиционном подходе _и изначальном знании о всех стадиях_, было бы необходимо сделать в счетчике поле явно указывающее текущую стадию, например: `uint public currentState`. При каждом вызове метода увеличения счетчика происходила бы проверка текущей стадии и выполнялся код ассоциированной с ней:

```js
function increaseCounter() public returns (uint) {
  if (currentState == 0) {
    value = value + 1;
  } else if (currentState == 1) {
    value = value + 10;
  }

  return value;
}
```

Чтобы наглядно продемонстрировать возможности обновляемых контрактов, согласимся, что у нас появится 3-ая стадия о которой мы пока не знаем и ее условия опишем в конце главы.

## Хралище

Для реализации слоя данных хранящего текущее значение счетчика и отделенного от бизнес-логики, создаем контракт – `~/contracts/base/UIntStorage.sol`:

[Source Url](https://github.com/alerdenisov/upgradable-contracts/blob/96b3cc4269ae9377c0cd3f733f4fdea1c6acbc5e/contracts/base/UIntStorage.sol)
```js
pragma solidity ^0.4.18;

contract UIntStorage {
  uint private value;

  function setValue(uint _value) external returns (uint) {
    value = _value;
    return value;
  }

  function getValue() external view returns (uint) {
    return value;
  }
}
```

Как видно из названия и реализации контракта – хранилище ничего не знает о том как его будут использовать и выполняет задачу инкапсуляции поля `uint private value`

## Бизнес-логика
Договоримся, что взаимодействие с нашей бизнес-логикой будет осуществляться через два метода: `increaseCounter` и `getCounter` для увеличения счетчика и получения текущего значения соответственно, о чем явно опишем в интерфейсе – `~/contracts/examples/counter/ICounter.sol`:

[Source Url](https://github.com/alerdenisov/upgradable-contracts/blob/8c1b4617038a98d04e898c4d7062b3a03ba3948d/contracts/examples/counter/ICounter.sol)
```js
pragma solidity ^0.4.18;

interface ICounter {
  function increaseCounter() public returns (uint);
  function getCounter() public view returns (uint);
}
``` 
Далее опишем смарт-контракт бизнес-логики из первой стадии реализующий `ICounter` интерфейс и использующий ранее описанное хранилище – `~/contracts/examples/counter/IncrementCounter.sol`:

[Source Url](https://github.com/alerdenisov/upgradable-contracts/blob/8c1b4617038a98d04e898c4d7062b3a03ba3948d/contracts/examples/counter/IncrementCounter.sol)
```js
pragma solidity ^0.4.18;

import "./ICounter.sol";
import "../../base/UIntStorage.sol";

contract IncrementCounter is ICounter {
  UIntStorage public counter;
  function IncrementCounter(address _storage) public {
    counter = UIntStorage(_storage);
  }
  function increaseCounter() public returns (uint) {
    return counter.setValue(getCounter() + 1);
  }
  function getCounter() public view returns (uint) {
    return counter.getValue();
  }
}
```

__Важно отметить__, что `IncrementCounter` не имеет внутреннего состояния (не хранит данные), кроме ссылки на хранилище.

_Если договориться передавать в метод `increaseCounter` и `getCounter` ссылку на хранилище первым аргуметом, можно реализовать стейт-лесс бизнес-логику_

Вносим изменения в `~/contracts/examples/counter/ICounter.sol`:

[Source Url](https://github.com/alerdenisov/upgradable-contracts/blob/a5be307196434b82cf89c556b8cb7bf51a887c38/contracts/examples/counter/ICounter.sol)
```js
pragma solidity ^0.4.18;

interface ICounter {
  function increaseCounter(address _storage) public returns (uint);
  function getCounter(address _storage) public view returns (uint);
  function validateStorage(address _storage) public view returns (bool);
}
```

Теперь методы бизнес-логики ждут первым агрументом ссылку на хранилище, а так же реализуют метод проверки хранилища на валидность: `validateStorage(address _storage)`

Внесем изменения в реализацию первой стадии – `~/contracts/examples/counter/IncrementCounter.sol`:
[Source Url](https://github.com/alerdenisov/upgradable-contracts/blob/a5be307196434b82cf89c556b8cb7bf51a887c38/contracts/examples/counter/IncrementCounter.sol)
```js
pragma solidity ^0.4.18;

import "./ICounter.sol";
import "../../base/UIntStorage.sol";

contract IncrementCounter is ICounter {
  modifier validStorage(address _storage) {
    require(validateStorage(_storage));
    _;
  }

  function increaseCounter(address _storage) 
    validStorage(_storage) 
    public returns (uint) 
  {
    UIntStorage counter = UIntStorage(_storage);
    require(counter.isUIntStorage());
    return counter.setValue(counter.getValue() + 1);
  }

  function getCounter(address _storage) 
    validStorage(_storage) 
    public view returns (uint) 
  {
    UIntStorage counter = UIntStorage(_storage);
    require(counter.isUIntStorage());
    return counter.getValue();
  }

  function validateStorage(address _storage) 
    public view returns (bool) 
  {
    return UIntStorage(_storage).isUIntStorage();
  }
}
``` 

Перед переходом к реализации следующей стадии и обновлению контракта бизнес-логики, напишем пару тестов и убедимся, что бизнес-логика работает как запланировано.

## Тестирование

Данный репозиторий является проектом фреймворка _Truffle_ и предоставляет удобный функционал для тестирования: `truffle test`. 

__Я не буду подробно описывать процесс написания тестов__, но если эта тема вам интересна – напишите мне в телеграм @alerdenisov и я подготовлю статью с best-practice тестирования контрактов.

`~/test/IncrementCounter.test.js`:
```js
import expectThrow from './utils/expectThrow'

const IncrementCounter = artifacts.require('./IncrementCounter.sol')
const UIntStorage = artifacts.require('./UIntStorage.sol')
const BoolStorage = artifacts.require('./BoolStorage.sol')

contract('IncrementCounter', ([owner, user]) => {
  let counter, storage, fakeStorage
  before(async () => {
    storage = await UIntStorage.new()
    fakeStorage = await BoolStorage.new()
    counter = await IncrementCounter.new()
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
})
```

Запуск тестов покажет, что все "прекрасно":
```
  Contract: IncrementCounter
    ✓ Should receive 0 at begin
    ✓ Should increase value on 1 (63ms)
    ✓ Should store 1 after increment
    ✓ Should validate storage
    ✓ Should unvalidate fake storage

  5 passing (301 ms)
```


Но на самом деле это не так. Допишем промежуточный тест "неавторизированного" взаимодействия с хранилищем:

```js
  it('Should prevent non-authenticated write', async () => {
    await expectThrow(storage.setValue(100))
  })
```

```
  Contract: IncrementCounter
    ✓ Should receive 0 at begin
    ✓ Should increase value on 1 (58ms)
    1) Should prevent non-authenticated write
    2) Should store 1 after increment
    ✓ Should validate storage
    ✓ Should unvalidate fake storage


  4 passing (330ms)
  2 failing
```

[Source Url](https://github.com/alerdenisov/upgradable-contracts/blob/e585fdff06240ec45e7eb14ce8b8b2761e132a1c/test/IncrementCounter.test.js)


## Владение хранилищем
Проблема текущего решения в том, что хранилище никак не ограничивает запись и злоумышленик может изменить данные в хранилище игнорирую бизнес-логику контракта счетчика.

Основное преимущество смарт-контрактов в том, что они гарантируют участникам обмена то, что данные (состояние) не будет изменено никак иначе кроме как декларирует смарт-конракт. __Но сейчас изменения ничем не ограничены.__

__Задача__ сделать так, чтобы изменять хранилище мог исключительно актуальный контракт бизнес-логики.

Для явного ограничения взаимодействия с хранилищем, воспользуемся паттерном `Ownable` из фреймворка `zeppelin-solidity` (подробнее c паттерном можно ознакомиться в документации к фреймворку).

Наследуем хранилище от `Ownable` контракта и добавим модификатор `onlyOwner` на метод `setValue()`:

[Source Url](https://github.com/alerdenisov/upgradable-contracts/blob/969d0500da0a4f9b5be97c5509e28add7e26380c/contracts/base/UIntStorage.sol)
```js
pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract UIntStorage is Ownable {
  uint private value;

  function setValue(uint _value) onlyOwner external returns (uint) {
    value = _value;
    return value;
  }

  function getValue() external view returns (uint) {
    return value;
  }

  function isUIntStorage() external pure returns (bool) {
    return true;
  }
}
```

Поздравляю, теперь в наше хранилище может писать только ассоциированный владелец хранилища! Теперь уже 3 из 6 теста проваливаются! Давайте в тестах "в ручную" передадим бизнес-логики управление хранилищем:


[Source Url](https://github.com/alerdenisov/upgradable-contracts/blob/dc9e38e4b3ad176558efbdb30b19f3a836c2757c/test/IncrementCounter.test.js)
```js
  before(async () => {
    storage = await UIntStorage.new()
    fakeStorage = await BoolStorage.new()
    counter = await IncrementCounter.new()

    await storage.transferOwnership(counter.address)
  })
```

Теперь все тесты проходят, но встает второй вопрос: "Как управлять владением хранилища при обновлении бизнес-логики"

## Общий контроллер

Перед реализацией общего контроллера сделаем еще один контракт счетчика, но уже второй стадии – `~/contracts/examples/counter/IncrementCounterPhaseTwo.sol`:

[Source Url](https://github.com/alerdenisov/upgradable-contracts/blob/dc9e38e4b3ad176558efbdb30b19f3a836c2757c/contracts/examples/counter/IncrementCounterPhaseTwo.sol)
```js
pragma solidity ^0.4.18;

import "./IncrementCounter.sol";

contract IncrementCounterPhaseTwo is IncrementCounter {
  function increaseCounter(address _storage) 
    validStorage(_storage) 
    public returns (uint) 
  {
    UIntStorage counter = UIntStorage(_storage);
    return counter.setValue(counter.getValue() + 10);
  }
}
```

Теперь когда у нас есть две реализации счетчика и `Ownable` хранилище, становится понятно, что необходимо как-то "просить" одну реализацию отдать другой управление хранилищем. Добавим метод `transferStorage(address _storage, address _counter)` в интерфейс счетчиков – `~/contracts/examples/counter/ICounter.sol`:

[Source Url](https://github.com/alerdenisov/upgradable-contracts/blob/dc9e38e4b3ad176558efbdb30b19f3a836c2757c/contracts/examples/counter/ICounter.sol)
```js
pragma solidity ^0.4.18;

interface ICounter {
  function increaseCounter(address _storage) public returns (uint);

  function getCounter(address _storage) public view returns (uint);

  function validateStorage(address _storage) public view returns (bool);

  function transferStorage(address _storage, address _counter) public returns (bool);
}
```

Договоримся, что финальная реализация `ICounter` должна  после вызова метода `transferStorage` отдавать управление хранилищем адресу переданному в параметр `_counter`:

[Source Url](https://github.com/alerdenisov/upgradable-contracts/blob/dc9e38e4b3ad176558efbdb30b19f3a836c2757c/contracts/examples/counter/IncrementCounter.sol)
```js
  function transferStorage(address _storage, address _counter) validStorage(_storage) public returns (bool) {
    return UIntStorage(_storage).transferOwnership(_counter);
  }
```

Давайте допишем тесты передачи прав новой логике и проверим результат `increaseCounter` метода после смены логики:

```js
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
```

Выполнение тестов может дать ложное ощущение, что все работает: 

```
  Contract: IncrementCounter
    ✓ Should receive 0 at begin
    ✓ Should increase value on 1 (75ms)
    ✓ Should prevent non-authenticated write
    ✓ Should store 1 after increment
    ✓ Should validate storage
    ✓ Should unvalidate fake storage
    ✓ Should transfer ownership
    ✓ Should reject increase from outdated counter
    ✓ Should increase counter with new logic (47ms)


  9 passing (500ms)
```

Но спешу вас огорчить, эти изменения опять открыли зеленный свет злоумышленикам:

```js
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
```
```
  Contract: IncrementCounter
    ✓ Should receive 0 at begin (46ms)
    ✓ Should increase value on 1 (55ms)
    ✓ Should prevent non-authenticated write
    ✓ Should store 1 after increment
    ✓ Should validate storage
    ✓ Should unvalidate fake storage
    ✓ Should transfer ownership
    ✓ Should reject increase from outdated counter
    ✓ Should increase counter with new logic (46ms)
    1) Should reject non-authenticated transfer storage
    2) Should reject increase from user fron previous test
    3) Should store 11 as before

  9 passing (611ms)
  3 failing
```

__Основная задача__ общего контроллера будет управлять передачей прав и не допускать кого-угодно к этому процессу. Сначала изменим `IncrementCounter` по аналогии с `UIntStorage`, чтобы он тоже наследовал логику `Ownable` и ограничивал взаимодействие с хранилищем:

[Source Url](https://github.com/alerdenisov/upgradable-contracts/blob/2f3547721e003d639a562ed87f36b3353c8557bf/contracts/examples/counter/IncrementCounter.sol)
```js
pragma solidity ^0.4.18;

import "./ICounter.sol";
import "../../base/UIntStorage.sol";

contract IncrementCounter is ICounter, Ownable {
  modifier validStorage(address _storage) {
    require(validateStorage(_storage));
    _;
  }
  
  function increaseCounter(address _storage) 
    onlyOwner validStorage(_storage) 
    public returns (uint) 
  {
    UIntStorage counter = UIntStorage(_storage);
    require(counter.isUIntStorage());
    return counter.setValue(counter.getValue() + 1);
  }

  function getCounter(address _storage) 
    validStorage(_storage) 
    public view returns (uint) 
  {
    UIntStorage counter = UIntStorage(_storage);
    require(counter.isUIntStorage());
    return counter.getValue();
  }
  
  function validateStorage(address _storage) 
    public view returns (bool) 
  {
    return UIntStorage(_storage).isUIntStorage();
  }
  
  function transferStorage(address _storage, address _counter)
    onlyOwner validStorage(_storage) 
    public returns (bool) 
  {
    UIntStorage(_storage).transferOwnership(_counter);
    return true;
  }
}
```

Приступи к реализации контроллера. Основные требования к контроллеру:
1) Учет текущей реализации счетчика
2) Обновление реализации счетчика
2) Перемещение прав на хранилище при обновлении реализации
3) Отклонение попыток неавторизированного обновление реализации

`~/contracts/examples/counter/CounterContrller.sol`:

[Source Url](https://github.com/alerdenisov/upgradable-contracts/blob/2f3547721e003d639a562ed87f36b3353c8557bf/contracts/examples/counter/CounterController.sol)
```js
pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./ICounter.sol";
import "../../base/UIntStorage.sol";

contract CounterController is Ownable {
  UIntStorage public store = new UIntStorage();

  ICounter public counter;

  event CounterUpdate(address previousCounter, address nextCounter);

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

  function increaseCounter() public returns (uint) {
    return counter.increaseCounter(store);
  }

  function getCounter() public view returns (uint) {
    return counter.getCounter(store);
  }
}
```

`increaseCounter` и `getCounter` не более, чем просто внешние методы взаимодействия с аналогичными в текущей реализации `ICounter`. Вся логика контроллера находится в небольшом методе: `updateCounter(address _counter)`.

Метод `updateCounter` принимает адресс на реализацию счетчика и перед установкой его как адреса новой реализации счетчика? передает ему права на хранилище (от себя или от предыдущей в зависимости от состояния).

_Помните про третью стадию?_ Я опущу код ее реализации, тем более, что отличается от второй только одной строчкой. Просто скажу, что в третьей стадии счетчик будет увеличивать значение умножением на самого себя: `value = value * value`.

Давайте напишем немного тестов и убедимся, что контроллер работает и выполняет поставленные перед ним задачи:

```js
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

```
```
  Contract: CounterController
    ✓ Shoult create storage
    ✓ Should change counter implementation (53ms)
    ✓ Should increase counter on 1 (52ms)
    ✓ Should update counter (55ms)
    ✓ Should increase counter on 10 after update (56ms)
    ✓ Should reject non-authenticated update
    ✓ Should update on phase three and increase counter to 11*11 after execution (89ms)


  7 passing (684ms)
```

Как видите контроллер свою задачу выполняет, а код нашего счетчика стал обновляемым.

# Резюме
Не смотря на абстрактность (и абсурдность) примера, подход можно применять в реальных контрактах. Например, для обеспечения обновляемости игровой логики в проекте Evogame, я использую данный подход в контрактах реализующих карты монстров, логику боя и т.д.

Но у данного подхода есть ряд существенных недостатков и комментариев:
- __Увеличивается стоимость транзакций__ (объем потребляемого газа), но не значительно. Если есть желающие провести подсчеты – буду признателен или ожидайте в ближайшем будущем от меня.
- __Появляется роль администратора__, но решается передачей прав на контроллер смарт-контракту децентрализованного голосования за принятие обносвлений
- __Сложность проектирования__, писать код в одном монолитном контексте в разы проще и требует меньше внимания к потокам данных и сообщений. Реализация state-less требует еще большего внимания от разработчика. Решается вызовом реализации через `delegatecall`. Напишите мне если нужно написать продолжение с передачей состояния через `delegatecall`.