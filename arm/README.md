# Azure Virtual Desktop ARM Templates

このディレクトリには、Azure Virtual Desktop (AVD) インフラストラクチャの ARM テンプレートが含まれています。Terraform の構成に基づいて分割されています。

## ファイル構成

### ルートテンプレート
- **main.json** - すべてのサブテンプレートをリンクする、デプロイ用のメインテンプレート

### リソーステンプレート
- **resource_group.json** - リソースグループの作成
- **network.json** - Virtual Network とサブネット
- **nsg.json** - Network Security Groups とルール
- **storage_account.json** - ストレージアカウント（FSLogix プロファイル用）
- **monitor.json** - Log Analytics Workspace と Data Collection Rules
- **group.json** - Azure AD グループとロール割り当て
- **azure_virtual_desktop.json** - AVD リソース（ホストプール、アプリケーショングループ、ワークスペース、セッションホスト VM）
- **bastion.json** - Azure Bastion（オプション、デフォルトで無効）

### パラメータ
- **parameters.json** - 共通パラメータの定義スキーマ

## デプロイ方法

### Azure CLI を使用したデプロイ

```bash
# サブスクリプションレベルでのデプロイ
az deployment sub create \
  --name avd-deployment \
  --location japaneast \
  --template-file main.json \
  --parameters @parameters.json \
  --parameters prj="at-avd" env="dev09" \
    subscriptionId="your-subscription-id" \
    tenantId="your-tenant-id" \
    sessionHostAdminPassword="your-secure-password"
```

### Azure Portal を使用したデプロイ

1. Azure Portal で「テンプレートのデプロイ」を選択
2. カスタムテンプレートを構築を選択
3. main.json の内容をエディタに貼り付け
4. 必要なパラメータを入力してデプロイ

## パラメータ

| パラメータ | 型 | デフォルト | 説明 |
|----------|-----|-----------|------|
| subscriptionId | string | - | Azure Subscription ID |
| tenantId | string | - | Azure Tenant ID |
| prj | string | - | プロジェクト名 |
| env | string | - | 環境名 |
| location | string | japaneast | Azure リージョン |
| sessionHostVmSize | string | Standard_D2s_v3 | セッションホスト VM のサイズ |
| sessionHostAdminUsername | string | azureuser | セッションホスト管理者ユーザー名 |
| sessionHostAdminPassword | securestring | - | セッションホスト管理者パスワード |
| sessionHostCount | int | 1 | セッションホスト VM の数 |
| addressSpace | string | 10.0.0.0/16 | Virtual Network アドレス空間 |
| defaultSubnetPrefix | string | 10.0.1.0/24 | デフォルトサブネット アドレスプレフィックス |
| privateEndpointSubnetPrefix | string | 10.0.10.0/24 | プライベートエンドポイント サブネット アドレスプレフィックス |

## テンプレートの依存関係

```
resource_group
├── monitor
├── group
├── storage_account
├── network
│   └── nsg
│       └── azure_virtual_desktop
│           └── (すべてのリソース)
└── bastion (オプション)
```

## Terraform との対応関係

| ARM テンプレート | Terraform ファイル |
|------------------|-------------------|
| resource_group.json | resource_group.tf |
| network.json | network.tf |
| nsg.json | nsg.tf |
| storage_account.json | storage_account.tf |
| monitor.json | monitor.tf |
| group.json | group.tf |
| azure_virtual_desktop.json | azure_virtual_desktop.tf |
| bastion.json | bastion.tf |

## 注意事項

1. **Azure AD グループ** - group.json では Azure AD リソース（グループ作成など）は含まれていません。これらは Azure AD モジュールまたは Microsoft Graph API を使用して別途作成してください。

2. **セッションホスト初期化スクリプト** - azure_virtual_desktop.json では、GitHub からスクリプトを取得します。スクリプトの URL が変更された場合は、テンプレートを更新してください。

3. **セッションホスト登録** - セッションホストの自動登録には、registration token が使用されます。

4. **Bastion** - bastion.json はデフォルトで無効です。deployBastion パラメータを true に設定してから、AzureBastionSubnet をデプロイしたVNetに追加してください。

## トラブルシューティング

### デプロイエラー
- サブスクリプション ID とテナント ID が正しいか確認
- パスワード要件を確認（大文字、小文字、数字、特殊文字を含む）
- アドレス空間の競合がないか確認

### リソース作成エラー
- ストレージアカウント名が Azure 全体で一意か確認（ストレージアカウント名は小文字のみ）
- リージョンにおける API サポートを確認
- 割り当て制限（クォータ）を確認

## ライセンスと注意事項

これらのテンプレートは Terraform 構成を基にしています。セッションホスト VM には Windows Client ライセンスが使用されています。
