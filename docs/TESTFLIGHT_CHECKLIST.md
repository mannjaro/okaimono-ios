# TestFlight 提出前チェックリスト

コード側のリファインは完了済みです。提出直前に以下を確認してください。

## 自動検証（実施済み）

- Debug ビルド成功
- Release ビルド成功（`generic/platform=iOS`）
- ユニットテスト成功（正規化 / サジェスト / カート集約 / Core Data保存 / カスケード削除 / ディスクストア再読込・リセット）
- UI スモークテスト: 起動 → リスト作成 → 詳細タブ表示

## 手動確認（実機推奨）

1. リスト作成 → 献立追加 → 材料追加 → カートで購入済み切替
2. 材料名・分量のインライン編集後、アプリを即終了して再起動し、内容が残ること
3. リスト / 献立をスワイプ削除すると即座に消えること
4. 空状態の案内文が表示されること
5. iCloud サインイン状態で別端末（または再インストール）と同期すること
6. オフラインで編集し、オンライン復帰後に同期されること
7. ストア読込エラー画面の「再試行」でデータ削除が起きないこと
8. 必要な場合だけ「ローカルデータをリセット」を明示的に選び、再作成後にCloudKitデータが再同期されること

## App Store Connect / 署名

1. Xcode で **Product > Archive** し、Organizer から TestFlight へ Upload
2. Archive 後の entitlements で次を確認
   - `com.apple.developer.icloud-container-identifiers` = `iCloud.mannjaro.okaimono-app`
   - `aps-environment` が Distribution では `production` になっていること（Automatic Signing なら通常はプロファイル側で付与）
3. CloudKit Dashboard で Development スキーマを **Deploy to Production**
4. Beta App Review 情報
   - 連絡先
   - テスト手順（上記手動確認の要約）
   - 「iCloud アカウントが必要」「iOS 26.5 以上」など
5. プライバシー
   - プライバシーポリシー URL
   - サポート URL
   - データ種類（ユーザーコンテンツ / iCloud 同期）の申告

## 今回入れた主なコード変更

- Core Data 起動失敗時のエラー画面 + 再試行 + 明示確認付きローカルストア再作成
- CloudKit互換の **optional属性モデル**（required化は不採用）と軽量マイグレーション有効化
- モデル非互換時はリセット案内を表示（一時的なiCloudエラーでは自動削除しない）
- Store Trump 競合ポリシー / 保存失敗アラート / バックグラウンド移行時の保存
- 献立・材料の編集保存タイミング修正
- 未使用 Background Modes 削除（`remote-notification` のみ残置）
- 表示名「おかいもの」/ 暗号化申告 / App Icon 全スロット
- UI 日本語化、空状態、スワイプ即削除、カートの Button 化

## 実機で「データを読み込めませんでした」が出る場合

1. まず「再試行」
2. 続く場合のみ「ローカルデータをリセット」→確認後に実行（iCloud上のレコードは残る）
3. アプリを再起動し、リストが再同期または新規作成できることを確認
