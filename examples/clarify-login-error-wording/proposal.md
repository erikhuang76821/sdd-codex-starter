<!-- 對抗性審查來源: 無 (理由: 純 spec scenario 錯誤訊息文字修正, 不增減 capability, 不改 status code, 無方向決定可被對抗性審查) -->

## Why

`user-login` capability 的 spec scenario「[異常] 密碼錯誤」目前要求錯誤訊息是「帳號或密碼錯誤」, 但客服反映台灣同事看到時容易誤以為是「帳號錯誤**或**密碼錯誤分別發生」, 導致以為帳號被停用 → 多了 30% 的工單。本 change 把訊息改寫為「帳號或密碼有誤」, 行為不變 (status code 401 不變、常數時間比對不變), 只調整使用者看到的文字。

## What Changes

- spec scenario「[異常] 密碼錯誤」的訊息文字: 「帳號或密碼錯誤」→「帳號或密碼有誤」
- spec scenario「[異常] 帳號不存在」維持與上述完全相同的訊息 (本來就是這個約束)
- 前端 i18n 字串檔對應更新

## Capabilities

### New Capabilities
<!-- 無 -->

### Modified Capabilities
- `user-login`: 僅 scenario 內錯誤訊息文字微調, 行為 / status code / 時間特性全部不變

## Impact

- 影響: 前端登入頁顯示文字; 客服 FAQ 文件 (另案同步)
- 依賴: 既有 i18n pipeline
- 風險: 極低 — 純文案, 無 API contract 變動
