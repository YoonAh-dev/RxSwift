##  [순환 참조](https://www.notion.so/RxSwift-1-1-00d8316ab70440eb907ecd60c243b602#04825ac2c58541128d59dd406dee4f6c) 

▶️ **순환 참조 때문에 문제가 생김 -> `reference count`증가**

- `reference count`가 다시 감소될 때는 이 `closure`가 없어질 때 ❗️❗️ 
  → 언제 없어지나 `completed`, `error`일때
  - 역할이 다 했기 때문에 감소
  
```swift
DispatchQueue.main.async {
                    f.onNext(json)
                    f.onCompleted()
}
```
- json 데이터 하나 내려주고 끝났다고 알려줌 → 아무것도 처리 안하지만 `closure`가 스스로 사라지고 `reference count`가 감소
  ⇒ `onCompleted`를 통해서 순환참조 문제를 해결(메모리에 없어짐)
  
<br/>
 
```swift
func downloadJson(_ url: String) -> Observable<String?> {
        // 1. 비동기로 생기는 데이터를 Observable로 감싸서 리턴하는 방법
        return Observable.create { f in
            DispatchQueue.global().async {
                let url = URL(string: url)!
                let data = try! Data(contentsOf: url)
                let json = String(data: data, encoding: .utf8)
                DispatchQueue.main.async {
                    f.onNext(json)
                    f.onCompleted()
                }
            }
            return Disposables.create()
        }
    }

@IBAction func onLoad() {
        editView.text = ""
        setVisibleWithAnimation(self.activityIndicator, true)
        
        // 2. Observable로 오는 데이터를 받아서 처리하는 방법
        downloadJson(MEMBER_LIST_URL)
            .subscribe { event in
                switch event {
                case let .next(json) :
                    self.editView.text = json
                    self.setVisibleWithAnimation(self.activityIndicator, false)
                case .completed:
                    break
                case .error:
                    break
                }
            }
        // RxSwift를 다 익힌 것
    }
```

<br/>

## Observable의 생명주기

1. create() → create됐다고 해서 모든 데이터가 생성, 전달되거나 하지 않음
2. subscribe() → subscribe를 해야지 동작을 한다
3. onNext로 전달 
4. completed / onError 되면서 끝
5. dispose()
- `create`한다고 URLSession이 실행되지 않음
- 결국 만들어 놓는다고 실행 X , subscribe가 되면 실행 O
- 실행되고 나서야 `next`, `completed`, `error` 중에 하나 발생 → `next`로 계속 전달, 제대로 전달 `completed`, 아니면 `error`
- 모든 동작이 끝나야지 `dispose` → 제대로 전달 중에 `dispose`해서 cancel하면 바로 `dispose`
- 4번부터는 동작이 끝났다고 보면 된다.
- 한 `subscribe`는  `completed`, `onerror`, `dispose`로 끝나고 끝난 observable은 재사용 불가능
- 다시 새로운 `subscribe`를 만들어야지 동작 가능 → 생명주기가 끝났기 때문에

      2020-10-24 16:15:03.827: ViewController.swift:97 (onLoad()) -> subscribed
      2020-10-24 16:15:03.971490+0900 RxSwift+MVVM[28026:1529092] [] nw_protocol_get_quic_image_block_invoke dlopen libquic failed
      2020-10-24 16:15:04.974: ViewController.swift:97 (onLoad()) -> Event next(Optional("[{\"id\":1,\"name\":\"Berenice

      ...

      2020-10-24 16:15:04.985: ViewController.swift:97 (onLoad()) -> Event completed
      2020-10-24 16:15:04.985: ViewController.swift:97 (onLoad()) -> isDisposed
      이러한 생명주기

<br/>
<br/>

## Observable로 오는 데이터를 받아서 처리하는 방법

```swift
@IBAction func onLoad() {
        editView.text = ""
        setVisibleWithAnimation(self.activityIndicator, true)
        
        let observable = downloadJson(MEMBER_LIST_URL)

        // 2. Observable로 오는 데이터를 받아서 처리하는 방법
        observable.subscribe()
    }
```


- 데이터를 처리하기 위해서는 closure 달아줘야 함

  → subscribe는 disposable를 return → disposable은 필요에 따라 dispose() 호출 가능 

```swift
@IBAction func onLoad() {
        editView.text = ""
        setVisibleWithAnimation(self.activityIndicator, true)
        
        let observable = downloadJson(MEMBER_LIST_URL)

        // 2. Observable로 오는 데이터를 받아서 처리하는 방법
        let disposable = observable.subscribe { event in
            switch event {
            case .next(let json):
                break
            case .error(let err):
                break
            case .completed:
                break
            }
        }
    }
```

- event closure가 순환 참조를 일으키는데 이 closure는 이 observable이 종료될 때 사라진다

- 종료되는 조건은 생명주기의 `4, 5`
