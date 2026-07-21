# AVD ARM テンプレート デプロイ手順

このフォルダには、`/infra` の Terraform 構成をベースにした **分割 ARM テンプレート** が入っています。  
`azuredeploy.json`（親）から `modules/*.json` を呼び出す構成です。

## 構成

- `azuredeploy.json` : 親テンプレート
- `azuredeploy.parameters.json` : デプロイ時パラメータ
- `modules/network.json` : VNet / Subnet
- `modules/nsg.json` : NSG / ルール / Subnet への関連付け
- `modules/monitor.json` : Log Analytics / DCR / VMInsights
- `modules/avd-core.json` : Host Pool / DAG / Workspace / 診断設定
- `modules/storage.json` : FSLogix 用 Storage / File Share / Private Endpoint / Private DNS
- `modules/session-hosts.json` : セッションホスト VM（任意）
- `deploy.ps1` : 分割テンプレートをインライン展開して `az deployment group create` を実行するヘルパー

## 前提

- Azure CLI (`az`) が利用可能
- PowerShell 5.1+ または PowerShell 7+
- デプロイ先サブスクリプションに十分な権限があること

## 1. パラメータを編集

`azuredeploy.parameters.json` を環境に合わせて変更します。特に以下は必須です。

- `sessionHostAdminPassword.value`（強力なパスワードへ変更）
- `prj.value`, `env.value`（命名プレフィックス）
- `location.value`

> `sessionHostCount.value` が `0` の場合、セッションホスト VM は作成されません（AVD 基盤のみ作成）。

## 2. Azure ログイン

```powershell
az login --use-device-code
```

## 3. デプロイ実行

```powershell
cd arm
.\deploy.ps1 `
  -SubscriptionId "9be1289f-3360-481b-9f14-b3f065b28177" `
  -ResourceGroupName "at-avd-armtest-rg" `
  -Location "japaneast" `
  -DeploymentName "avd-arm-001"
```

## 4. デプロイ結果の確認

```powershell
az deployment group show `
  --resource-group at-avd-armtest-rg `
  --name avd-arm-001 `
  --query properties.outputs -o json
```

## 備考

- `deploy.ps1` は、親テンプレート内の `templateLink` をローカルモジュール JSON で置換した一時テンプレートを作成してからデプロイします。
- 一時ファイルはデプロイ後に自動削除されます。
