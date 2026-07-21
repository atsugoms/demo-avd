# demo-avd

このリポジトリでは、Azure Virtual Desktop (AVD) 環境を **2つの方法**でデプロイできます。

- **Terraform デプロイ**: `terraform/README.md`
- **ARM Template デプロイ**: `arm/README.md`

## デプロイされる構成（概要）

主に以下の AVD 基盤リソースを作成します。

- リソース グループ
- 仮想ネットワーク (`10.0.0.0/16`) とサブネット（セッションホスト用 / Private Endpoint 用）
- Network Security Group（RDP 許可ルール含む）
- AVD Host Pool / Desktop Application Group / Workspace
- 監視基盤（Log Analytics Workspace, Data Collection Rule, VMInsights）
- FSLogix 用 Storage Account / File Share / Private Endpoint / Private DNS
- （任意）Windows 11 AVD セッションホスト VM と拡張機能（Entra ログイン、初期化スクリプト、AVD 登録、AMA）

> 補足: Terraform 版には Entra グループ作成とロール割り当ても含まれます。

## デプロイ手順

詳細手順は各 README を参照してください。

- Terraform: `terraform/README.md`
- ARM Template: `arm/README.md`