## [2교시] RxSwift 활용하기 - 쓰레드의 활용과 메모리 관리

1. Stream의 분리 및 병합
    - `share`
    - `combine`, `merge`, `zip`
    
<br/>

▶️ 병합하는 API가 몇 개 존재 → Combining에 관련된 Observables

<br/>

<img src="https://s3.us-west-2.amazonaws.com/secure.notion-static.com/744b7aec-dd0d-4bd3-b105-6b473200acff/_2020-10-31__12.12.34.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAT73L2G45O3KS52Y5%2F20201101%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20201101T113958Z&X-Amz-Expires=86400&X-Amz-Signature=8189b3a053354444d441415f4e1bfadb19fa37d48506bd4258c5c3512898b077&X-Amz-SignedHeaders=host&response-content-disposition=filename%20%3D%22_2020-10-31__12.12.34.png%22" width="90%"></img>


**Merge, Zip, CombineLatest를 가장 많이 사용**

- merge : `observable`이 두 개 → 여러 개 `observable`를 하나의 `observable`로 만들어 주는 것
  ⇒ 하나로 합쳐서 데이터를 순서대로 나타내기(두개의 데이터 타입이 같아야 함)
- Zip : 위아래 데이터가 하나씩 생성되면 쌍으로 만들어서 내려보냄
  → 데이터가 하나만 있으면 아래로 전달이 안됨, 밑에도 뭔가 데이터가 있어줘야 함
  → 하나는 빨리 왔는데 다른 건 늦게 오면 나중에 오는 거랑 쌍 만들어서 내려줌
  → 데이터 타입이 서로 달라도 상관이 없다
- CombineLatest : Zip이랑 비슷한데, Zip은 밑에 쌍이 없으면 못 내려오는데 얘는 쌍이 없으면 가장 최근에 들어온 것과 쌍을 이뤄서 내려간다

<br/>

```swift
let jsonObservable = downloadJson(MEMBER_LIST_URL)
let helloObservable = Observable.just("Hello World")
            
        Observable.zip(jsonObservable, helloObservable) { $1 + "\n" + $0 }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { json in
                    self.editView.text = json
                        self.setVisibleWithAnimation(self.activityIndicator, false)})
```

- zip 하는 것 → helloworld를 먼저 출력하고 그 다음에 데이터를 받아옴

<br/>


## disposeBag


```swift
override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        disposable?.dispose()
    }
```

- 이렇게 하면 다운로드 하는 중간에라도 다운을 멈추고 나가기 가능
  ⇒ 만약 화면 안에 dispose할 작업들이 여러개 있다면 `var disposable : [Disposable] = []` 이렇게 배열로 만들고 `disposable.append(d)`

```swift
var disposable: [Disposable] = []

override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        disposable.forEach { $0.dispose() }
}

let d = Observable.zip(jsonObservable, helloObservable) { $1 + "\n" + $0 }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { json in
                    self.editView.text = json
                        self.setVisibleWithAnimation(self.activityIndicator, false)})
disposable.append(d)
```

▶️ **여러개의 비동기로 들어가는 처리들이 `disposable` 등록했다가 한 꺼번에 `dispose` 시킬 수 있음**

- 근데 이것도 `Sugar`가 제공이 된다❗️❗️ → DisposeBag()

- 멤버 변수이기 때문에 이 클래스가 날라갈 때 → 애가 가지고 있는 `disposable`이 한꺼번에 날라감

```swift
var disposable = DisposeBag()

let jsonObservable = downloadJson(MEMBER_LIST_URL)
let helloObservable = Observable.just("Hello World")
            
let d = Observable.zip(jsonObservable, helloObservable) { $1 + "\n" + $0 }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { json in
                    self.editView.text = json
                        self.setVisibleWithAnimation(self.activityIndicator, false)})
disposable.insert(d)
```

- `insert`해주면 된다. 하지만 변수 받아서 넣고 하기 귀찮음 
  → disposable이 `.disposed(by: disposableBag)`를 제공해줘서 `Bag`를 저기에 넣어주면 받았다가 넣지 않아도 바로 이어서 넣어준다.

```swift
let d = Observable.zip(jsonObservable, helloObservable) { $1 + "\n" + $0 }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { json in
                    self.editView.text = json
                    self.setVisibleWithAnimation(self.activityIndicator, false)})
						.disposed(by: disposable)
```

#### 간결하게 여러 sugar를 사용해서 처리 


<br/>


## 정리

### ✅ RxSwift

- 나중에 생기는 데이터(Observable)
- Observable 데이터 꺼내 쓸려면 subscribe
- Observable 만드는 방법 
  - `create` 생성해서 `next`로 데이터 전달
  - 적절한 시점에 `error`를 내보내주던가
  - 적절한 시점에 `completed`
  - 중간에 동작을 취소 시키는 건 `dispose`

- subscribe 하는 방법은 `next`, `complete`, `error` 이벤트 중 어느게 오냐를 받아서 적절하게 처리

▶️ 기본적인 사용 방법, RxSwift를 return값으로 처리하기 위한 유틸리티 그런 용도로 사용

▶️ 그에 대한 기본 사용 방법이 `create`, `subscribe`

<br/>

### 근데 위에 있는 방법이 너무 기니깐 그에 대한 sugar들을 제공해주는 데 → operator

- operator : 생성(just, from), 데이터 중간 전달에 변환, 필터링, 쓰레드 바꿔서 처리 가능

  → `ObserveOn`, `subscribeOn`에는 scheduler를 넣는 것 <br/>
  → scheduler는 RxSwift가 `OperationQueue를 rapping` 한 것 <br/>
  → 그래서 scheduler를 넣어줘야 한다 <br/>
  → `MainScheduler`는 하나밖에 없기 때문에 생성하지 않고 이미 만들어져 있는 `instance`를 가져다가 넣음 <br/>

- subscribe 할 때도 이벤트를 다 받는 게 아니라, 내가 처리할 이벤트 그것만 따로 지정해서 사용 <br/>

  → return값으로 `disposable`이 나오는 데 평소에는 의미 없음, 무시해도 상관없음 <br/>
  → 하지만 내가 취소하고 싶은 동작이 있을 때, 명확하게 취소하고 싶을 때 그 `disposable`를 가지고 있다가 `dispose`를 호출해주면 그 동작 취소 가능 <br/>
  
  
<br/>
<br/>

2. 순환참조와 메모리 관리
    - `Unfinished Observable` / `Memory Leak`
    - (참조) [클로져와 메모리 해제 실험](https://iamchiwon.github.io/2018/08/13/closure-mem/)

<br/>

▶️**클로져가 사라지면 클로져가 들고 있던 reference count도 같이 내려 놓는다**

<img src="https://s3.us-west-2.amazonaws.com/secure.notion-static.com/af47b5df-c2e9-4ae2-b0a3-405bbb774455/_2020-11-01__5.01.07.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAT73L2G45O3KS52Y5%2F20201101%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20201101T120055Z&X-Amz-Expires=86400&X-Amz-Signature=411b525b9e02318d7d2061e2a2ef8a88463fab0142b4a4f410df39a31c4b0bd8&X-Amz-SignedHeaders=host&response-content-disposition=filename%20%3D%22_2020-11-01__5.01.07.png%22" width="90%"></img>

- `didMove`의 parent가 nil로 들어오면 `pop()` <br/>
  → 이 때 `disposeBag`를 일부러 날려버린다

- disposeBag <br/>
  → 클래스의 `reference count`가 증가한 상태면 `disposeBag`은 안 날라감 <br/>
  → 따라서 일부러 날려주는 거임(pop 될 때 reference count를 얼마로 잡고 있던간에 날려버리니깐)
