# Sign-In-With-Apple
詳細註解 如何使用Sign In With Apple

Sign In with Apple

1. 不再需要密碼, 直接適用Apple ID 作為帳號登入
2. 使用者可以選擇使用假的email 登入
3. Apple Sign In 可以跨平台 iOS , Web, Android 
4. 若原來使用者已經存了 password 在iCloud keyChain , 可以利用ASAuthorizationPasswordProvider 發出請求, 作為登入，避免多餘的帳戶
5. userID 可用來查驗使用者目前Apple ID 的帳號狀態
* authorized: 已認證
* notFound: 用户可能尚未將帳號與Apple ID绑定
* revoked: 帳號已註銷
 
資料來源: 
2019 WWDC-Introducing Sign In with Apple
https://developer.apple.com/videos/play/wwdc2019/706

新的認證機制

1. 如果是從 Web登入 , 我們需要將AppID 存在 我們的Server 上作為連結,  實際作法為 在 Web association 檔案中的apps 陣列中加上 
2. 如果是使用OAuth 做為登入的方式  , 使用ASWebAuthenticationSession 來開啟認證

資料來源: 
2019 WWDC-What's New in Authentication
https://developer.apple.com/videos/play/wwdc2019/516/

兩個流程

1. 通過Apple登錄驗證用戶身份

圖解:  客戶端AppID 發起登入請求 -> 要求獲取使用者資訊 -> 驗證使用者並且獲得identityToken-> 回傳使用者fullName, email ,identityToken, user identifier 等資訊(fullName, email只有第一次會回傳)

identity token 為JSON Web Token(JWT) 內容包含
* kid (key ID): 密鑰ID
* alg: 演算法
* iss: 發行者註冊的聲明密鑰，其值為。https://appleid.apple.com
* sub: 用戶的唯一標識符。 
* aud: 您在您的Apple Developer帳戶中。client_id
* exp: token的到期時間。該值通常設置為5分鐘。
* iat: token發行的時間。
* nonce(臨時的): 一個字符串值，用於關聯客戶端會話和ID token。該值用於緩和 replay attacks，僅在授權請求期間通過時才存在。
* email: 用戶的電子郵件地址。
* email_verified: 一個布爾值，指示服務是否已驗證電子郵件。此聲明的值始終為true，因為服務器僅返回經過驗證的電子郵件地址

user identifier 
* 作為用戶主要識別符
* 使用相同識別符對於相同開發團隊的所有app
* 通常與user 的primary key 一起存在database 中 ，並取代email 作為用戶辨識

realUserStatus
* LikelyReal
* Unknown
* Unsupported
只有第一次登入時會回傳結果 , 之後無論是重新連結還是換裝置都是 Unknown



2. 驗證用戶

圖解: 客戶端向後台提交 token (identityToken) 和 userID , 後台和 Apple server要 public key 並且用其對用戶的identity token 進行驗證，如果成功返回Refresh token -> 通知客戶端結果

0. Apple signIn 認證順序:
Face ID or Touch ID on passcode-protected devices
>Passcode, if Touch ID or Face ID isn’t available
>Apple ID password, if the passcode isn’t set
1.Apple 用 on-device machine learning 的方式決定使用者是否為假帳號
2.使用者只要在其中一個裝置上登入過Sign In With Apple 就可以在其他裝置上登入同個APP , 就算是刪除APP也不影響
3.fullName 還有email 只有第一次登入apple sign in 第一台裝置的時候會問, 除非用戶停止使用sign In With Apple 且重新登入，所以如果需要需先存在本地端
4.user identifier 取代了原本email , 做為辨識用戶的識別
5.user identifier 型態Data , 為JWT Web Token , APP 送給後端, 讓後端找Apple去認證是否為有效的token
6. 為了驗證JWT Token 後端必須
* 使用服務器的公鑰驗證JWS E256簽名
* 驗證nonce身份驗證
* 驗證該iss字段包含https://appleid.apple.com
* 驗證該aud字段是開發人員的client_id
* 驗證時間早於exp token的值

練習專案:
如何SignInWithApple (Github Repo: )

資料來源:
APPLE 官網->
Authenticating Users with Sign in with Apple
https://developer.apple.com/documentation/signinwithapplerestapi/authenticating_users_with_sign_in_with_apple
Verifying a User
https://developer.apple.com/documentation/signinwithapplerestapi/verifying_a_user
其他-> 
iOS13 Sign In With Apple适配
http://jerryliu.org/ios%20programming/iOS13-Sign-With-Apple%E6%96%B0%E7%89%B9%E6%80%A7%E9%80%82%E9%85%8D
iOS 13 苹果账号登陆与后台验证相关
https://juejin.im/post/5d551d11e51d4561cf15dfae
