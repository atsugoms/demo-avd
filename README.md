
# AVD 環境 デプロイ手順

## リソースのデプロイ

1. デプロイ用の変数ファイルを準備

    `/infra/terraform.tfvars.example` をコピーして `/infra/terraform.tfvars` を作成

    | key | value |
    |---|---|
    | subscription_id | サブスクリプションID |
    | tenant_id | テナントID |
    | prj | プロジェクト名(任意名) |
    | env | 環境名(任意名) |
    | session_host_vm_size        | セッションホストVMサイズ (例: `Standard_B2as_v2` ) |
    | session_host_admin_username | ローカルユーザー名 |
    | session_host_admin_password | ローカルユーザーパスワード |
    | session_host_count          | ホスト数 |

1. Azure へログイン

    ```
    az login --use-device-code
    ```

1. デプロイ

    ```
    cd infra
    terraform init
    terraform apply --auto-approve
    ```


## RBAC の 設定

1. デプロイ完了したら以下の2グループができているので、M365ライセンスのあるユーザーをどちらかに所属させる

    - `{prj}-{env}-avd-admins` (管理ユーザー)
    - `{prj}-{env}-avd-users` (一般ユーザー)


## AVD へ アクセス

1. Webまたはデスクトップアプリでログイン

    - Web アプリ:
        - https://windows.cloud.microsoft/
    - デスクトップ アプリ:
        - [Windows](https://apps.microsoft.com/detail/9N1F85V9T8BN)
        - [macOS](https://aka.ms/macOSWindowsApp)

