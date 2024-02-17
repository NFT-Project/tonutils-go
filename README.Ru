# tonutils-go

<img align="right" width="425px" src="https://github.com/xssnick/props/blob/master/logoimg.png?raw=true">

# tonutils-go

<img align="right" width="425px" src="https://github.com/xssnick/props/blob/master/logoimg.png?raw=true">

[![Основано на TON][ton-svg]][ton]
![Coverage](https://img.shields.io/badge/Coverage-73.3%25-brightgreen)

Библиотека Golang для взаимодействия с блокчейном TON.

Эта библиотека является нативной golang-реализацией ADNL и протокола lite. Она работает как пул соединений и может быть подключена к нескольким серверам lite в одно и то же время, балансировка осуществляется на стороне либы.

Он безопасен для одновременной работы и может использоваться из нескольких горутин при высоких рабочих нагрузках.

Реализованы все основные протоколы TON: ADNL, DHT, RLDP, Overlays, HTTP-RLDP и т.д.

------

Если вам нравится эта библиотека и вы хотите поддержать ее развитие, вы можете пожертвовать любое количество монет на этот ton-адрес ☺️
`EQBx6tZZWa2Tbv6BvgcvegoOQxkRrVaBVwBOoW85nbP37_Go`

### Как использовать
- [Соединение](#Connection)
- [Кошелек](#Wallet)
  - [Пример](https://github.com/xssnick/tonutils-go/blob/master/example/wallet/main.go)
  - [Создать](#Кошелек)
  - [Перевести](#Кошелек)
  - [Баланс](#Кошелек)
  - [Перевести многим](https://github.com/xssnick/tonutils-go/blob/master/example/highload-wallet/main.go)
  - [Отправить сообщение на контракт](https://github.com/xssnick/tonutils-go/blob/master/example/send-to-contract/main.go)
  - [Создать транзакцию и отправить из другого места](https://github.com/xssnick/tonutils-go/blob/master/example/wallet-cold-alike/main.go#L61)
- [Счета](#Account-info-and-transactions)
  - [Список транзакций](#Account-info-and-transactions)
  - [Получить баланс](https://github.com/xssnick/tonutils-go/blob/master/example/account-state/main.go)
  - [Подписка на транзакции](https://github.com/xssnick/tonutils-go/blob/master/example/accept-payments/main.go)
- [NFT](#NFT)
  - [Подробности](#NFT)
  - [Монетный двор](https://github.com/xssnick/tonutils-go/blob/master/example/nft-mint/main.go#L42)
  - [Перевод](https://github.com/xssnick/tonutils-go/blob/master/ton/nft/integration_test.go#L89)
- [Jettons](#Jettons)
  - [Подробности](#Jettons)
  - [Transfer](https://github.com/xssnick/tonutils-go/blob/master/example/jetton-transfer/main.go)
- [DNS](#DNS)
  - [Resolve](#DNS)
  - [Получить записи](#Records)
  - [Set records](#Records)
- [Contracts](#Contracts)
  - [Использовать методы получения](#Using-GET-methods)
  - [Отправить внешнее сообщение](#Send-external-message)
  - [Развернуть](#Deploy)
- [Cells](#Cells)
  - [Create](#Cells)
  - [Parse](#Cells)
  - [TLB Loader/Serializer](#TLB-Loader)
  - [BoC](#BoC)
- [Network](https://github.com/xssnick/tonutils-go/tree/master/adnl)
  - [ADNL UDP](https://github.com/xssnick/tonutils-go/blob/master/adnl/adnl_test.go)
  - [TON Site request](https://github.com/xssnick/tonutils-go/blob/master/example/site-request/main.go)
  - [RLDP-HTTP Клиент-Сервер](https://github.com/xssnick/tonutils-go/blob/master/example/http-rldp-highload-test/main.go)
- [Custom reconnect policy](#Custom-reconnect-policy)
- [Features to implement](#Features-to-implement)


Примеры использования можно найти в каталоге **[example](https://github.com/xssnick/tonutils-go/tree/master/example)**.

Вы также можете присоединиться к нашей **[Telegram группе](https://t.me/tonutils)** и задать любые вопросы :)

### Соединение
Список публичных lite-серверов можно получить из официальных конфигов TON:
* Mainnet - `https://ton.org/global.config.json`
* Testnet - `https://ton-blockchain.github.io/testnet-global.config.json`.

В разделе liteservers нужно преобразовать int в ip, взять порт и ключ.

Или вы можете запустить свою собственную полноценную ноду, смотрите документацию TON.

Вы можете подключиться так:
``golang
client := liteclient.NewConnectionPool()

configUrl := "https://ton-blockchain.github.io/testnet-global.config.json"
err := client.AddConnectionsFromConfigUrl(context.Background(), configUrl)
if err != nil {
    panic(err)
}
api := ton.NewAPIClient(client)
api = api.WithRetry() // если вы хотите автоматических повторных попыток с переходом на другой узел
```

Поскольку `client` реализует пул соединений, может возникнуть вероятность того, что какой-то блок еще не применен на одном из узлов, что может привести к ошибкам.
Если вы хотите привязать все запросы операции к одному узлу, используйте 
``go
ctx := client.StickyContext(context.Background())
```
И передайте этот контекст методам.

### Кошелек
Вы можете использовать существующий кошелек или сгенерировать новый с помощью `wallet.NewSeed()`, кошелек будет инициализирован первым сообщением, отправленным с него. Эта библиотека развернет и инициализирует контракт кошелька, если он еще не инициализирован. 

Вы также можете отправить любое сообщение любому контракту, используя метод `w.Send`, он принимает структуру `tlb.InternalMessage`, вы можете погрузиться в реализацию `w.Transfer` и посмотреть, как это работает.

Пример базового использования:
``golang
words := strings.Split("шаблон рождения ...", " ")

w, err := wallet.FromSeed(api, words, wallet.V3)
if err != nil {
    panic(err)
}

balance, err := w.GetBalance(context.Background(), block)
if err != nil {
    panic(err)
}

if balance.Nano().Uint64() >= 3000000 {
  
    addr := address.MustParseAddr("EQCD39VS5jcptHL8vMjEXrzGaRcCVYto7HUn4bpAOg8xqB2N")
    err = w.Transfer(context.Background(), addr, tlb.MustFromTON("0.003"), "Эй, братан, с днем рождения!")
    if err != nil {
        panic(err)
    }
}
```
Полный рабочий пример вы можете найти в `example/wallet/main.go`
### Контракты 
Вот описание функций, которые позволяют нам вызывать методы контракта

#### Использование методов GET
Представим, что у нас есть контракт с методом
``func
cell mult(int a, int b) method_id {
  return begin_cell().store_uint(a * b, 64).end_cell();
}
```

Мы можем запустить его и получить результат следующим образом:
``golang
// api = инициализированный ton.APIClient, см. Connection в readme

// нам нужна свежая информация о блоке, чтобы запустить методы get
block, err := api.CurrentMasterchainInfo(context.Background())
if err != nil {
    panic(err)
}

// адрес контракта
addr := address.MustParseAddr("kQB3P0cDOtkFDdxB77YX-F2DGkrIszmZkmyauMnsP1gg0inM")

// запускаем метод получения `mult` контракта с аргументами int 7 и 8
res, err := api.RunGetMethod(context.Background(), block, addr, "mult", 7, 8)
if err != nil {
    // если код выхода по контракту != 0, то это тоже будет считаться ошибкой
    panic(err)
}

// мы уверены, что возвращаемое значение - 1 ячейка, мы можем напрямую привести его и разобрать
val, err := res.MustCell(0).BeginParse().LoadUInt(64)
if err != nil {
    panic(err)
}

// печатает 56
println(val)
```

#### Отправка внешнего сообщения
С помощью сообщений вы можете взаимодействовать с контрактами для изменения состояния. Например, с его помощью можно взаимодействовать с кошельком и отправлять транзакции другим.

Вы можете отправить сообщение контракту следующим образом:
``golang
// тело сообщения
data := cell.BeginCell().
    MustStoreUInt(777, 64).
    EndCell()

// адрес договора
addr := address.MustParseAddr("kQBkh8dcas3_OB0uyFEDdVBBSpAWNEgdQ66OYF76N4cDXAFQ")

// отправьте внешнее сообщение, плата за обработку будет взята из контракта
err = api.SendExternalMessage(context.Background(), addr, data)
if err != nil {
    panic(err)
}
```
Полный рабочий пример вы можете найти в файле `example/external-message/main.go`.

#### Развертывание
Контракты могут быть развернуты с помощью метода кошелька `DeployContract`, 
вы должны передать туда 3 ячейки: код контракта, начальные данные контракта, тело сообщения.

Пример можно посмотреть [здесь](https://github.com/xssnick/tonutils-go/blob/master/example/deploy-nft-collection/main.go)

### Информация о счете и транзакции
С помощью метода GetAccount вы можете получить полную информацию о счете, включая баланс, сохраненные данные и даже код. 
Вы также можете получить список транзакций счета со всеми подробностями.

Пример:
``golang
// Аккаунт Фонда ТОН
addr := address.MustParseAddr("EQCD39VS5jcptHL8vMjEXrzGaRcCVYto7HUn4bpAOg8xqB2N")

account, err := api.GetAccount(context.Background(), b, addr)
if err != nil {
    log.Fatalln("get account err:", err.Error())
    return
}

// Баланс: АКТИВНЫЙ
fmt.Printf("Статус: %s\n", account.State.Status)
// Баланс: 66559946.09 TON
fmt.Printf("Баланс: %s TON\n", account.State.Balance.String())
if account.Data != nil { // Может быть nil, если счет не активен
    // Данные: [0000003829a9a31772c9ed6b62a6e2eba14a93b90462e7a367777beb8a38fb15b9f33844d22ce2ff]
    fmt.Printf("Данные: %s\n", account.Data.Dump())
}

// загрузка последних 15 транзакций
list, err := api.ListTransactions(context.Background(), addr, 15, account.LastTxLT, account.LastTxHash)
if err != nil {
    // В некоторых случаях вы можете получить ошибку:
    // ошибка lite-сервера, код XXX: cannot compute block with specified transaction: lt not in db
    // это означает, что текущий lite-сервер не хранит старые данные, вы можете запросить один с полной историей
    log.Printf("send err: %s", err.Error())
    return
}

// старейший = первый в списке
for _, t := range list {
    // Out: 620.9939549 TON, To [EQCtiv7PrMJImWiF2L5oJCgPnzp-VML2CAt5cbn1VsKAxLiE]
    // In: 494.521721 TON, From EQB5lISMH8vLxXpqWph7ZutCS4tU4QdZtrUUpmtgDCsO73JR 
    // ....
    fmt.Println(t.String())
}
```
Расширенный рабочий пример вы можете найти в `example/account-state/main.go`

### NFT
Вы можете майнить, передавать и получать информацию о NFT, используя `nft.ItemClient` и `nft.CollectionClient`, вот так:
``golang
api := ton.NewAPIClient(client)

nftAddr := address.MustParseAddr("EQDuPc-3EoqH72Gd6M45vmFsktQ8AzqaN14mweJhCjxg0d_b")
item := nft.NewItemClient(api, nftAddr)

nftData, err := item.GetNFTData(context.Background())
if err != nil {
    panic(err)
}

// получаем информацию о коллекции нашего nft
collection := nft.NewCollectionClient(api, nftData.CollectionAddress)
collectionData, err := collection.GetCollectionData(context.Background())
if err != nil {
    panic(err)
}

fmt.Println("Адрес коллекции :", nftData.CollectionAddress.String())
fmt.Println(" содержимое :", collectionData.Content.(*nft.ContentOffchain).URI)
fmt.Println(" владелец :", collectionData.OwnerAddress.String())
fmt.Println(" minted items num :", collectionData.NextItemIndex)
fmt.Println()
fmt.Println("NFT addr :", nftAddr.String())
fmt.Println(" инициализировано :", nftData.Initialized)
fmt.Println(" владелец :", nftData.OwnerAddress.String())
fmt.Println(" index :", nftData.Index)

if nftData.Initialized {
    // преобразуем содержимое в ячейку, она нужна нам для получения полного url
    nftContentCell, err := nftData.Content.ContentCell()
    if err != nil {
        panic(err)
    }

    // получаем полный url содержимого nft, используя метод коллекции, который объединит базовый url с данными nft
    nftContent, err := collection.GetNFTContent(context.Background(), nftData.Index, nftContentCell)
    if err != nil {
        panic(err)
    }
    fmt.Println(" содержимое части :", nftData.Content.(*nft.ContentOffchain).URI)
    fmt.Println(" полное содержимое :", nftContent.(*nft.ContentOffchain).URI)
} else {
    fmt.Println(" пустое содержимое")
}
```
Полные примеры вы можете найти в `example/nft-info/main.go` и `example/nft-mint/main.go`.

### Джеттоны
Вы можете получить информацию о джеттоне, получить кошелек джеттона и его баланс, перевести джеттоны и сжечь их, используя `jetton.Client` следующим образом:
``golang
// адрес контракта джеттона
contract := address.MustParseAddr("EQAbMQzuuGiCne0R7QEj9nrXsjM7gNjeVmrlBZouyC-SCLlO")
master := jetton.NewJettonMasterClient(api, contract)

// получение информации о jetton
data, err := master.GetJettonData(context.Background())
if err != nil {
    log.Fatal(err)
}

log.Println("total supply:", data.TotalSupply.Uint64())

// получаем кошелек jetton для аккаунта
ownerAddr := address.MustParseAddr("EQC9bWZd29foipyPOGWlVNVCQzpGAjvi1rGWF7EbNcSVClpA")
jettonWallet, err := master.GetJettonWallet(context.Background(), ownerAddr)
if err != nil {
    log.Fatal(err)
}

jettonBalance, err := jettonWallet.GetBalance(context.Background())
if err != nil {
    log.Fatal(err)
}
log.Println("баланс:", jettonBalance.String())
```
Полный пример, который также содержит трансфер, вы можете найти по адресу `example/jettons/main.go`

### DNS
Вы можете получить информацию о доменах, получить подключенный кошелек и любые другие записи, передать домен, отредактировать и выполнить любые другие nft-совместимые операции, используя `dns.Client`, например:
``golang
resolver := dns.NewDNSClient(api, dns.RootContractAddr(api))

domain, err := resolver.Resolve(context.Background(), "alice.ton")
if err != nil {
    panic(err)
}

log.Println("домен указывает на адрес кошелька:", domain.GetWalletRecord())
```
Полный текст примера можно найти в файле `example/dns/main.go`.

##### Записи

Вы можете получить любую запись домена, используя метод `domain.GetRecord("имя записи")`, он вернет ячейку, которая будет содержать структуру данных, зависящую от типа записи. 
Также можно использовать `domain.GetWalletRecord()` и `domain.GetSiteRecord()`, они вернут уже разобранные данные, например, адрес для кошелька или фрагмент байта с типом для сайта.

Для установки записей домена вы можете использовать `domain.BuildSetRecordPayload("имя записи", dataCell)`, или предопределенные `BuildSetSiteRecordPayload(adnlAddress)`, `BuildSetWalletRecordPayload(walletAddress)`.
Она сгенерирует ячейку тела, которую нужно отправить в контракт домена из кошелька владельца.

Пример:
``golang
// получаем корневой dns-адрес из конфигурации сети
root, err := dns.RootContractAddr(api)
if err != nil {
    panic(err)
}

resolver := dns.NewDNSClient(api, root)
domainInfo, err := resolver.Resolve(ctx, "utils.ton")
if err != nil {
    panic(err)
}

// подготавливаем ячейку полезной нагрузки транзакции, которая изменит запись адреса сайта
body := domainInfo.BuildSetSiteRecordPayload(adnlAddr)

// w = wallet.FromSeed("seed phrase владельца домена")
err = w.Send(context.Background(), &wallet.Message{
  Mode: 1, // оплата комиссии отдельно (от баланса, а не от суммы)
  InternalMessage: &tlb.InternalMessage{
    Bounce: true, // возврат суммы в случае ошибки обработки
    DstAddr: domainInfo.GetNFTAddress(), // местом назначения является контракт домена
    Сумма: tlb.MustFromTON("0.03"),
    Тело: тело,
  },
}, true)
if err != nil {
    panic(err)
}

// готово! Теперь запись на вашем сайте изменена!
```

### Ячейки
Работа с ячейками очень похожа на работу с ячейками FunC:
``golang
builder := cell.BeginCell().MustStoreUInt(0b10, 2).
    MustStoreUInt(0b00, 2). // src addr_none
    MustStoreAddr(addr).    // dst addr
    MustStoreCoins(0) // плата за импорт 0

builder.MustStoreUInt(0b11, 2). // имеет состояние init как ячейка
    MustStoreRef(cell.BeginCell().
        MustStoreUInt(0b00, 2).                     // нет глубины разбиения, нет специального
        MustStoreUInt(1, 1).MustStoreRef(code).     // с кодом
        MustStoreUInt(1, 1).MustStoreRef(initData). // с данными
        MustStoreUInt(0, 1).                        // без libs
    EndCell()).
    MustStoreUInt(0, 1). // данные среза
    MustStoreUInt(0, 1) // 1 бит в качестве тела, потому что он необходим

result := builder.EndCell()

// {bits_size}[{hex_data}]
// 279[8800b18cc741b244e114685e1a9e9dc835bff5c157a32a38df49e87b71d0f0d29ba418] -> {
// 5[30] -> {
// 0[],
// 8[01]
// }
// }

fmt.Println(result.Dump())
```

Загрузка из ячейки:
``golang
slice := someCell.BeginParse()
wc := slice.MustLoadUInt(8)
data := slice.MustLoadSlice(256)
```
Существует 2 типа методов `Must` и regular. Разница в том, что в случае ошибки `Must` вызовет панику, 
а обычный просто вернет ошибку, поэтому используйте `Must` только тогда, когда вы уверены, что ваши данные соответствуют максимальному размеру ячейки и другим условиям.

Для отладки ячеек можно использовать методы `Dump()` и `DumpBits()` ячейки, они вернут строку с красиво отформатированными ячейками и их деревом ссылок
##### BoC

Иногда требуется импортировать или экспортировать ячейку, например, для передачи по сети, для этого существует формат сериализации Bag of Cells.

Вы можете просто экспортировать ячейку, используя метод `ToBOC()` ячейки, и импортировать ее, используя `cell.FromBOC(bytes)`.

[Пример использования можно найти в тестах](https://github.com/xssnick/tonutils-go/blob/master/tvm/cell/cell_test.go#L76) или в примере [transfer-url-for-qr](https://github.com/xssnick/tonutils-go/blob/master/example/transfer-url-for-qr/main.go)

### TLB Loader
Вы также можете загружать ячейки в структуры, подобные JSON, используя теги. 
Подробности можно найти в комментарии-описании метода `tlb.LoadFromCell`.

Пример:
``golang
type ShardState struct {
    _ Magic `tlb: "#9023afe2"`.
    GlobalID int32 `tlb: "## 32"`
    ShardIdent ShardIdent `tlb:"."`
    Seqno uint32 `tlb: "## 32"`
    OutMsgQueueInfo *cell.Cell `tlb:"^"`
    Accounts struct {
        ShardAccounts *cell.Dictionary `tlb: "dict 256"`
    } `tlb:"^"`
}

type ShardIdent struct {
    PrefixBits int8 `tlb: "## 6"`
    WorkchainID int32 `tlb: "## 32"`
    ShardPrefix uint64 `tlb: "## 64"`
}

var state ShardState
if err = tlb.LoadFromCell(&state, cl.BeginParse()); err != nil {
    panic(err)
}
```

#### Сериализация TLB
Также можно сериализовать структуры обратно в ячейки с помощью `tlb.ToCell`, смотрите [build NFT mint message](https://github.com/xssnick/tonutils-go/blob/master/ton/nft/collection.go#L189), например.

### Пользовательская политика переподключения
По умолчанию будет использоваться стандартный метод переподключения - `c.DefaultReconnect(3*time.Second, 3)`, который будет делать 3 попытки и ждать 3 секунды после каждой.

Но вы можете использовать свою собственную логику переподключения, эта библиотека поддерживает обратные вызовы, в данном случае можно использовать обратный вызов OnDisconnect, который можно задать следующим образом:
``golang
client.SetOnDisconnect(func(addr, serverKey string) {}
	// ... сделайте что-нибудь
})
```

### Особенности для реализации
* ✅ Поддержка cell и slice в качестве аргументов для запуска метода get
* ✅ Переподключение при сбое
* ✅ Метод получения состояния учетной записи
* ✅ Отправка внешнего сообщения
* ✅ Получить транзакции
* ✅ Развернуть контракты
* ✅ Операции с кошельком
* ✅ Поддержка словарей ячеек
* ✅ Методы MustLoad
* ✅ Разбор глобального конфига json
* ✅ Джеттоны
* ✅ DNS
* ✅ ADNL UDP Client/Server
* ✅ RLDP клиент/сервер
* ✅ TON Sites Client/Server
* ✅ Клиент DHT
* ✅ Доказательства Меркла
* ✅ Клиент хранилища TON
* ✅ Оверлеи
* ✅ Парсер/сериализатор TL
* ✅ Парсер/сериализатор TL-B
* ✅ Каналы оплаты
* ✅ Liteserver доказывает автоматическую валидацию
* DHT Server
* TVM

<!-- Значки -->
[ton-svg]: https://img.shields.io/badge/Based%20on-TON-blue
[ton]: https://ton.org
[tg-chat]: https://t.me/tonutils
