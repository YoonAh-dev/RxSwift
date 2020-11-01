### **[1교시] 개념잡기 - RxSwift를 사용한 비동기 프로그래밍**

1. Observable
    - Observable `create`
    - subscribe 로 데이터 사용
    - Disposable 로 작업 취소

<br/>

✅ **비동기 스레드 : 다른 스레드를 사용해서 내가 하고 있는 본 작업을 진행하고, 원하는 작업을 비동기적으로 수행한 다음에 결과를 비동기적으로 받아서 처리를 하는 코드**

<br/>


```swift
   func downloadJson(_ url: String) -> String? {
        let url = URL(string: MEMBER_LIST_URL)!
        let data = try! Data(contentsOf: url)
        let json = String(data: data, encoding: .utf8)
        return json
    }

    @IBAction func onLoad() {
        editView.text = ""
        self.setVisibleWithAnimation(self.activityIndicator, true)
        DispatchQueue.global().async {
            let json = self.downloadJson(MEMBER_LIST_URL)
            
            DispatchQueue.main.async {
                self.editView.text = json
                self.setVisibleWithAnimation(self.activityIndicator, false)
            }
        }
    }
```

▶️ **구현부에 DispatchQueue를 `onLoad`에 두지 않고 downloadJson에 두고 싶음.**

    ✅ DispatchQueue들을 벗겨내면 동기적으로 처리한 것과 동일 
    ✅ setVisibleWithAnimation, text들은 main 스레드에서 돌아가는 것이기에 downloadJson만 비동기적으로 처리해주면 됨
    (다른 스레드에서 처리하게)

- 그래서 downloadJson을 DispatchQueue를 넣는다. 하지만 문제 발생!!

    → `return`를 하지 못함 따라서 `completion` 사용(클로져를 사용해서 결과값을 전달)

    → `main`에서 `completion`를 전달해준다.

    → downloadJson의 `closure`로 넣어주기

    → `completion`에는 `@escaping` 써주기 ⇒ 안쓰면 에러가 떠요❗️❗️
    
- **escaping이 왜 필요한가요?**

  - 본체 함수가 끝나고 나서야 `completion`이 불려지기 때문에 본체가 끝나고 나서 나중에 실행되는 함수라는 것을 명시하려고 `escaping`를 사용한다.

  - `escaping`를 사용하면 수행되는 부분에서 전달되는 내용들이 `closure`을 통해 역할을 수행 → `escaping`이 없으면 수행을 안할 수도 있음

- **escaping 없이 optional 함수인 경우에는?**

  - `escaping`이 `default`여서 `escaping`를 명시해주지 않아도 된다.
  
<br/>

```swift
// @escaping 
func downloadJson(_ url: String, _ completion: @escaping (String?) -> Void) {
    DispatchQueue.global().async {
        let url = URL(string: MEMBER_LIST_URL)!
        let data = try! Data(contentsOf: url)
        let json = String(data: data, encoding: .utf8)
        DispatchQueue.main.async {
             completion(json)
        }
    }
}

@IBAction func onLoad() {
    editView.text = ""
    self.setVisibleWithAnimation(self.activityIndicator, true)
        
    downloadJson(MEMBER_LIST_URL) { json in
        self.editView.text = json
        self.setVisibleWithAnimation(self.activityIndicator, false)
    }
}

// optional
func downloadJson(_ url: String, _ completion: ((String?) -> Void)?) {
        DispatchQueue.global().async {
            let url = URL(string: MEMBER_LIST_URL)!
            let data = try! Data(contentsOf: url)
            let json = String(data: data, encoding: .utf8)
            DispatchQueue.main.async {
                completion?(json)
            }
        }
    }
```

    1️⃣ 깊게 처리해야 하니깐 귀찮아 진다. 
      → 그럼 return 값을 completion으로 전달하지 말고 리턴값으로 전달해줄 수 없을까? 그러면 사용이 편하고 간결해짐
      
    2️⃣ 비동기로 생기는 데이터를 어떻게 return값으로 만들지?
    
    3️⃣ 위의 방식으로 해주는 utility 생성 → 나중에생기는데이터<String?>라는 걸로 감싸기
    
    4️⃣ let json:나중에생기는데이터<String?> = downloadJson(MEMBER_LIST_URL) 이걸 받아서
      json.나중에생기면 { json in
           editView ..
      } 그 때 처리해야지 → 이런 식으로

**❗️❗️그래서 이걸 해보자❗️❗️**

<br/>

---

<br/>

▶️ **나중에생기는데이터는 closure를 가지고 있음** <br/>

▶️ **나중에오면이 실행되면 저장해뒀던 closure를 실행하면서 지금 들어온 closure를 전달**

   - `completion`없이 `return` 값으로 해결하는 방식 가능
  
   - `return`값으로 전달하는 utility들이 생겨남 ⇒ 그 중 하나가 PromiseKit(Bolt, RxSwift)

<br/>

✅ **RxSwift:  비동기로 생기는 결과값을 `completion(closur)`으로 전달하는 게 아니라 `return`값으로 전달하기 위해서 만들어진 utility 
→ 결과적으로 똑같은 동작을 하는 것**
<br/>

- 다른 점은 조금 옵션이 생겼다는 것 → f(json)이 아니라 `f.onNext(json)`이라는 것
- 여러 옵션이 들어 있음 → `completion` 처리, 취소도 시킬 수 있는 그런 기능이 더 추가된 utility가 Rx
- 받을 때도 `next`라는 state를 주고 처리
- 나중에 생기는 데이터, 클래스
- 나중에 오는 건 `Observable`로 처리하자 → 나중에 오는 데이터 처리는 '나중에오면'으로 처리하자
- 나중에 오면이 `subscribe`


<br/>

∴ RxSwift → 비동기적으로 생기는 데이터를 `return` 값으로 전달해주기 ⇒ 값 사용은 나중에 오면 메소드를 호출

### 🔁 Observable의 순서

  1. `subscribe`를 사용하고 나중에 오는 비동기적 행위를 Observable로 나타냄
  2. `subscribe`하면 `event`가 온다
  3. Observable 만들 때 `create`라는 함수를 사용 
  4. f에다가 바로 전달하지 않고 `onNext`를 넣기 
  
<br/>

- event가 3개가 오는데  `event.next`(데이터 전달), `completed`(완전히 전달되고 끝남), `error`(에러남)
- `subscribe`에서의 return 값은 `Disposables`이 나온다.
- `Disposables` 안에는 dispose()가 있어서 작업 시켜 놓은 프로세스가 끝나지 않았어도 dispose()하면 동작 취소
- 바로 취소하니깐 동작을 안하게 된다.
