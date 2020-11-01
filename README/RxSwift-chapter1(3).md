## Sugar API
  - 간단한 생성 : `just`, `from`
  - 필터링 : `filter`, `take`
  - 데이터 변형 : `map`, `flatMap`
  - 그 외 : [A Decision Tree of Observable Operators](http://reactivex.io/documentation/ko/operators.html)
  - Marble Diagram
      - [http://rxmarbles.com/](http://rxmarbles.com/)
      - [http://reactivex.io/documentation/operators.html](http://reactivex.io/documentation/operators.html)
      - [https://itunes.apple.com/us/app/rxmarbles/id1087272442?mt=8](https://itunes.apple.com/us/app/rxmarbles/id1087272442?mt=8)
        
<br/>

## RxSwift

▶️**사용법이 너무 길어요, 너무 귀찮아요 → 귀찮은 것들을 없애주는 추가적인 API가 더 존재**

- `create` 써서 길게 쓰지말고 `just`를 써서 쉽게 보내자

  ⇒ create해서 next로 데이터 전달하고 completed하는 거 이게 `just`

- `just`로 데이터를 두 개 보내고 싶은데? `just` 하나만 데이터를 보낼 수 있음 → 배열로 만들어서 보내라 `just(["Hello", "World"])`

- 배열에 있는 거 하나씩 하나씩 보내고 싶으면 `from`를 사용 → hello도 한 번 world도 한 번 내려감(`next`에서 받는 다는 말)

      just : optional("Hello world")

      just(["Hello", "World"]) : optional("Hello"), optional("World")

      from(["Hello","World"]) : optional("Hello") enter optional("World")


<br/>

## operator
[🗒 operator Docs](https://www.notion.so/RxSwift-1-2-5262420fc1104e1b986950c58c74b1b2#02bf0bcf5c9848f585ba4bf9353cfca0)

### create -> just, from

```swift
func downloadJson(_ url: String) -> Observable<String?> {
        return Observable.just("Hello world")
    //return Observable.just(["Hello", "World"])
    //return Observable.from(["Hello", "World"])
}
```

⇒ 여러 줄로 표현해야 하는 것을 한 줄로 간단하게 표현 가능

### subscribe

```swift
_ = downloadJson(MEMBER_LIST_URL).subscribe(onNext: { print($0) }, 
			onError: {err in print(err)}, onCompleted: { print("Com ")})
```

⇒ switch문으로 여러 줄 쓰지 않고 간단하게 표현 가능

### observeOn, subscribeOn

```swift
downloadJson(MEMBER_LIST_URL)
            .observeOn(MainScheduler.instance) //sugar : operator
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default))
      // default큐를 가지는 Dispatch thread가 처음부터 실행
      // 그러다가 ObserveOn을 만나면 해당 쓰레드로 변경
            .subscribe(onNext: { json in
                    self.editView.text = json
                        self.setVisibleWithAnimation(self.activityIndicator, false)})
```


- ObserveOn → 넣는 것도 `observable` 나오는 것도 `observable` <br/>
  ⇒ ObserveOn적용하면 그 다음부터 해당 쓰레드가 적용된다는 것 <br/>
  ⇒ 그 후부터는 뭘 하든 간에 그 쓰레드에서 동작을 한다.
- subscribeOn은 그 다음 쓰레드에 영향을 주는 것이 아니라 시작하는 쓰레드에 영향을 준다 <br/>
  ⇒ 맨 처음 시작을 어느 스레드에서 할거냐 이런 것(subscribeOn를 쓴 위치랑 상관없이 적용)
- **ObserveOn은 다음 줄에 영향, subscribeOn은 첫 줄에 영향**

### map, filter

```swift
downloadJson(MEMBER_LIST_URL)
            .map { json in json?.count ?? 0 }
            .filter { cnt in cnt > 0}
            .map { "\($0)"}
            .observeOn(MainScheduler.instance) //sugar : operator
            .subscribe(onNext: { json in
                    self.editView.text = json
                        self.setVisibleWithAnimation(self.activityIndicator, false)})
```
- map → `observable`이 있어야 그 다음 `observable`하고 연결해서 쓸 수 있음, 맵에서 지정한 변환 공식에 따라서 바뀐 다음에 밑으로 전달해줌
  ⇒ 중간에 json를 int로 바꿀수도 string으로 바꿀 수도 있는 map sugar
- filter → 중간에 filter 넣어서 조건으로 filtering 가능

### 그 외

- last → `completed`되는 시점에 맨 마지막 데이터가 전달, 첫 `observable`이 `complete`되어야 전달이 되는구나, `completed`안되면 전달이 안되는구나 알 수 있음
- buffer → 데이터가 여러개 전달되는데 `buffer 3`이라고 한다면 데이터가 3개씩 묶여서 하나로 내려옴, 데이터가 여러개 왔을 때 그걸 하나씩 묶어서 처리하려면 `buffer`를 사용하면 되겠구나
- Scan → 용도는 자주 되는데 사용법이 자주 헷갈리는 애, 두 개를 더해서 하나를 내려보냄
  ⇒ 새로운 값과 현재 값을 내려보내서 계산된 값을 더함
