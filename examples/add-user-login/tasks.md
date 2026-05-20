## 1. BFF endpoints

- [ ] 1.1 建立 `app/api/auth/login/route.ts`, 驗證帳密 → 發 session cookie → verified by: scenario "使用者送出有效帳密"
- [ ] 1.2 加入「密碼錯誤」與「帳號不存在」常數時間比對與相同錯誤訊息 → verified by: scenario "[異常] 帳號不存在"
- [ ] 1.3 建立 `app/api/auth/logout/route.ts` 廢止 session → verified by: scenario "使用者點登出"

## 2. 節流 (Server-side)

- [ ] 2.1 引入 Redis 客戶端並建立 `{userId: {failedCount, lockedUntil}}` 結構 → verified by: 無 (理由: 純資料儲存層接線, 無單一可觀察 scenario)
- [ ] 2.2 在 login route 內 +1 / reset / 鎖定邏輯 → verified by: scenario "第 5 次失敗後鎖定"
- [ ] 2.3 鎖定期間直接打 API 仍 423 (不可繞過) → verified by: scenario "[異常] 鎖定期間仍嘗試送出"
- [ ] 2.4 Redis 不可用時的 503 降級分支 → verified by: scenario "[異常] Redis / 計數儲存失敗"

## 3. 前端

- [ ] 3.1 `app/login/page.tsx` 表單 + AntD Form 整合 → verified by: scenario "使用者送出有效帳密"
- [ ] 3.2 401 攔截 + 「帳號或密碼錯誤」訊息 + 留住 email 清空密碼 → verified by: scenario "[異常] 密碼錯誤"
- [ ] 3.3 423 收到後 disable 表單 + 倒數計時器 → verified by: scenario "第 5 次失敗後鎖定"
- [ ] 3.4 登出按鈕 (放 AdminLayout navbar) + 清 Redux auth slice → verified by: scenario "使用者點登出"
- [ ] 3.5 401 in 已登入狀態時自動導向 /login + revoked 訊息 → verified by: scenario "[異常] 已 revoked 的 session 再次被使用"

## 4. Session payload

- [ ] 4.1 Session payload 加 `mfaVerified: true` 欄位 → verified by: scenario "本 change 內所有成功登入"
- [ ] 4.2 README 警示「mfaVerified 為 2FA capability 預留, 本期勿基於它做權限判斷」 → verified by: scenario "[異常] 未來 2FA capability 上線後本欄位被誤讀"

## 5. 收尾

- [ ] 5.1 對其他組 30 分鐘 walkthrough (含密碼處理位置 / 節流位置) → verified by: 無 (理由: 知識傳遞活動, 無 scenario)
- [ ] 5.2 archive: `openspec archive add-user-login` → verified by: 無 (理由: 流程動作, 無使用者可觀察行為)
