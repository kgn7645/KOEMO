# KOEMO デプロイメント・運用手順書

## 1. 概要

### 1.1 目的
本文書は、KOEMOアプリケーションの本番環境へのデプロイメント手順と継続的な運用方法を定義します。

### 1.2 デプロイメント戦略
- **Blue-Green デプロイメント**: ダウンタイムなしのリリース
- **段階的ロールアウト**: iOS App Store段階的配信
- **自動CI/CDパイプライン**: GitHub Actions使用
- **インフラ as Code**: Terraform/CloudFormation

### 1.3 環境構成
```
Development → Staging → Production
     ↓           ↓          ↓
  ローカル環境   テスト環境   本番環境
```

## 2. インフラストラクチャ

### 2.1 AWS 構成図

```
┌─────────────────────────────────────────────────────────┐
│                        AWS Cloud                        │
│                                                         │
│  ┌──────────────┐    ┌─────────────────────────────────┐ │
│  │     Route    │    │              VPC                │ │
│  │      53      │    │                                 │ │
│  │   (DNS)      │    │  ┌─────────────┐ ┌────────────┐ │ │
│  └──────────────┘    │  │   Public    │ │  Private   │ │ │
│          │            │  │   Subnet    │ │   Subnet   │ │ │
│  ┌──────────────┐    │  │             │ │            │ │ │
│  │ CloudFront   │    │  │ ┌─────────┐ │ │ ┌────────┐ │ │ │
│  │    (CDN)     │    │  │ │   ALB   │ │ │ │  ECS   │ │ │ │
│  └──────────────┘    │  │ └─────────┘ │ │ │ Fargate│ │ │ │
│                      │  │             │ │ └────────┘ │ │ │
│                      │  └─────────────┘ │            │ │ │
│                      │                  │ ┌────────┐ │ │ │
│                      │                  │ │MongoDB │ │ │ │
│                      │                  │ │ Atlas  │ │ │ │
│                      │                  │ └────────┘ │ │ │
│                      └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### 2.2 本番環境リソース構成

#### 2.2.1 コンピューティング
```yaml
ECS Fargate:
  Service: koemo-backend
  Task Definition:
    CPU: 1024 (1 vCPU)
    Memory: 2048 MB
    Replicas: 3 (最小) / 10 (最大)
  
Auto Scaling:
  Target CPU: 70%
  Scale Out: +2 tasks
  Scale In: -1 task
```

#### 2.2.2 ロードバランサー
```yaml
Application Load Balancer:
  Type: internet-facing
  Scheme: ipv4
  Health Check:
    Path: /health
    Interval: 30s
    Timeout: 5s
    Healthy Threshold: 2
    Unhealthy Threshold: 5
```

#### 2.2.3 データベース
```yaml
MongoDB Atlas:
  Tier: M30 (Dedicated)
  Storage: 40GB SSD
  Backup: Continuous
  Monitoring: 24/7
  
Redis ElastiCache:
  Node Type: cache.t3.medium
  Replicas: 2
  Backup: Daily
```

## 3. CI/CD パイプライン

### 3.1 GitHub Actions ワークフロー

#### 3.1.1 バックエンドデプロイ
```yaml
name: Backend Deployment

on:
  push:
    branches: [main]
    paths: ['backend/**']
  
  pull_request:
    branches: [main]
    paths: ['backend/**']

env:
  ECR_REPOSITORY: koemo-backend
  ECS_SERVICE: koemo-backend-service
  ECS_CLUSTER: koemo-production
  TASK_DEFINITION: koemo-backend-task

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: backend/package-lock.json
      
      - name: Install dependencies
        run: |
          cd backend
          npm ci
      
      - name: Run tests
        run: |
          cd backend
          npm run test:coverage
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: backend/coverage/lcov.info

  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run security audit
        run: |
          cd backend
          npm audit --audit-level moderate
      
      - name: Run Snyk security scan
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high

  build-and-deploy:
    needs: [test, security-scan]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ap-northeast-1
      
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1
      
      - name: Build, tag, and push image to Amazon ECR
        id: build-image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          cd backend
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          echo "image=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" >> $GITHUB_OUTPUT
      
      - name: Fill in the new image ID in the Amazon ECS task definition
        id: task-def
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        with:
          task-definition: infrastructure/task-definition.json
          container-name: koemo-backend
          image: ${{ steps.build-image.outputs.image }}
      
      - name: Deploy Amazon ECS task definition
        uses: aws-actions/amazon-ecs-deploy-task-definition@v1
        with:
          task-definition: ${{ steps.task-def.outputs.task-definition }}
          service: ${{ env.ECS_SERVICE }}
          cluster: ${{ env.ECS_CLUSTER }}
          wait-for-service-stability: true
      
      - name: Notify Slack
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          webhook_url: ${{ secrets.SLACK_WEBHOOK_URL }}
```

#### 3.1.2 iOS アプリデプロイ
```yaml
name: iOS App Deployment

on:
  push:
    tags: ['v*']

jobs:
  build-and-deploy:
    runs-on: macos-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '15.0'
      
      - name: Install dependencies
        run: |
          cd ios
          pod install
      
      - name: Import Code-Signing Certificates
        uses: Apple-Actions/import-codesign-certs@v2
        with:
          p12-file-base64: ${{ secrets.CERTIFICATES_P12 }}
          p12-password: ${{ secrets.CERTIFICATES_PASSWORD }}
      
      - name: Download Provisioning Profiles
        uses: Apple-Actions/download-provisioning-profiles@v1
        with:
          bundle-id: com.yourcompany.koemo
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
      
      - name: Build and Archive
        run: |
          cd ios
          xcodebuild archive \
            -workspace KOEMO.xcworkspace \
            -scheme KOEMO \
            -configuration Release \
            -archivePath build/KOEMO.xcarchive \
            CODE_SIGN_STYLE=Manual
      
      - name: Export IPA
        run: |
          cd ios
          xcodebuild -exportArchive \
            -archivePath build/KOEMO.xcarchive \
            -exportPath build/ \
            -exportOptionsPlist ExportOptions.plist
      
      - name: Upload to App Store Connect
        uses: Apple-Actions/upload-testflight-build@v1
        with:
          app-path: ios/build/KOEMO.ipa
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
```

### 3.2 Infrastructure as Code

#### 3.2.1 Terraform 構成
```hcl
# infrastructure/main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "koemo-terraform-state"
    key    = "production/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  name = "koemo-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["ap-northeast-1a", "ap-northeast-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = false
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "koemo-production"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "koemo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = module.vpc.public_subnets
  
  enable_deletion_protection = true
}

# ECS Service
resource "aws_ecs_service" "backend" {
  name            = "koemo-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 3
  
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight           = 1
  }
  
  network_configuration {
    security_groups = [aws_security_group.ecs_tasks.id]
    subnets         = module.vpc.private_subnets
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "koemo-backend"
    container_port   = 3000
  }
}
```

#### 3.2.2 ECS Task Definition
```json
{
  "family": "koemo-backend-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "1024",
  "memory": "2048",
  "executionRoleArn": "arn:aws:iam::ACCOUNT:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::ACCOUNT:role/koemoTaskRole",
  "containerDefinitions": [
    {
      "name": "koemo-backend",
      "image": "ACCOUNT.dkr.ecr.ap-northeast-1.amazonaws.com/koemo-backend:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        },
        {
          "name": "PORT",
          "value": "3000"
        }
      ],
      "secrets": [
        {
          "name": "MONGODB_URI",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:ACCOUNT:secret:koemo/mongodb"
        },
        {
          "name": "JWT_SECRET",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:ACCOUNT:secret:koemo/jwt"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/koemo-backend",
          "awslogs-region": "ap-northeast-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
```

## 4. デプロイメント手順

### 4.1 事前準備

#### 4.1.1 環境変数設定
```bash
# GitHub Secrets 設定が必要な項目
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
MONGODB_URI
JWT_SECRET
SKYWAY_API_KEY
APPSTORE_ISSUER_ID
APPSTORE_KEY_ID
APPSTORE_PRIVATE_KEY
SLACK_WEBHOOK_URL
SNYK_TOKEN
```

#### 4.1.2 インフラデプロイ
```bash
# Terraform でインフラ構築
cd infrastructure
terraform init
terraform plan -var-file="production.tfvars"
terraform apply -var-file="production.tfvars"
```

### 4.2 アプリケーションデプロイ

#### 4.2.1 バックエンドデプロイ
```bash
# 1. コードをプッシュ
git push origin main

# 2. GitHub Actions が自動実行
# - テスト実行
# - セキュリティスキャン
# - Docker イメージビルド
# - ECR プッシュ
# - ECS デプロイ

# 3. デプロイ確認
curl https://api.koemo.app/health
```

#### 4.2.2 iOS アプリデプロイ
```bash
# 1. バージョンタグ作成
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# 2. GitHub Actions が自動実行
# - Xcode プロジェクトビルド
# - Code Signing
# - IPA ファイル生成
# - TestFlight アップロード

# 3. App Store Connect で設定
# - TestFlight テスト配信
# - App Store 審査提出
# - 段階的配信設定
```

### 4.3 Blue-Green デプロイメント

#### 4.3.1 Blue-Green 切り替えスクリプト
```bash
#!/bin/bash
# deploy-blue-green.sh

set -e

CLUSTER_NAME="koemo-production"
SERVICE_NAME="koemo-backend-service"
NEW_TASK_DEF_ARN=$1

if [ -z "$NEW_TASK_DEF_ARN" ]; then
    echo "Usage: $0 <new-task-definition-arn>"
    exit 1
fi

echo "Starting Blue-Green deployment..."

# 現在のタスク定義を取得
CURRENT_TASK_DEF=$(aws ecs describe-services \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --query 'services[0].taskDefinition' \
    --output text)

echo "Current task definition: $CURRENT_TASK_DEF"
echo "New task definition: $NEW_TASK_DEF_ARN"

# 新しいタスク定義でサービス更新
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --task-definition $NEW_TASK_DEF_ARN

echo "Waiting for deployment to complete..."

# デプロイメント完了待ち
aws ecs wait services-stable \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME

# ヘルスチェック
echo "Performing health check..."
for i in {1..10}; do
    if curl -f https://api.koemo.app/health; then
        echo "Health check passed"
        break
    else
        echo "Health check failed, attempt $i/10"
        sleep 30
    fi
done

echo "Blue-Green deployment completed successfully"
```

## 5. 監視・アラート

### 5.1 CloudWatch メトリクス

#### 5.1.1 アプリケーションメトリクス
```yaml
Custom Metrics:
  - koemo.api.request.count
  - koemo.api.response.time
  - koemo.matching.queue.size
  - koemo.calls.active.count
  - koemo.users.online.count
  - koemo.messages.sent.count

AWS Metrics:
  - ECS CPU/Memory Utilization
  - ALB Request Count/Latency
  - ElastiCache CPU/Memory
```

#### 5.1.2 アラート設定
```yaml
Critical Alerts:
  - ECS Service Unhealthy: CPU > 80%
  - API Error Rate: > 5%
  - Database Connection: > 90%
  - Memory Usage: > 85%

Warning Alerts:
  - Response Time: > 500ms
  - Queue Size: > 100
  - Disk Usage: > 80%
```

### 5.2 ログ管理

#### 5.2.1 CloudWatch Logs 設定
```json
{
  "log_groups": [
    {
      "name": "/ecs/koemo-backend",
      "retention_days": 30
    },
    {
      "name": "/aws/apigateway/koemo",
      "retention_days": 14
    }
  ],
  "log_filters": [
    {
      "name": "ERROR_FILTER",
      "pattern": "[ERROR]",
      "alarm": true
    },
    {
      "name": "SECURITY_FILTER", 
      "pattern": "[SECURITY]",
      "alarm": true
    }
  ]
}
```

#### 5.2.2 構造化ログ例
```javascript
// バックエンドログ形式
const logger = winston.createLogger({
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  defaultMeta: {
    service: 'koemo-backend',
    version: process.env.APP_VERSION
  }
});

// 使用例
logger.info('User connected', {
  userId: 'user-123',
  action: 'websocket_connect',
  ip: '192.168.1.1',
  userAgent: 'KOEMO/1.0'
});

logger.error('Database connection failed', {
  error: error.message,
  stack: error.stack,
  component: 'mongodb',
  operation: 'findUser'
});
```

### 5.3 APM (Application Performance Monitoring)

#### 5.3.1 New Relic 設定
```javascript
// newrelic.js
exports.config = {
  app_name: ['KOEMO Backend'],
  license_key: process.env.NEW_RELIC_LICENSE_KEY,
  distributed_tracing: {
    enabled: true
  },
  logging: {
    level: 'info'
  }
};
```

## 6. セキュリティ

### 6.1 WAF (Web Application Firewall)

#### 6.1.1 AWS WAF ルール
```json
{
  "rules": [
    {
      "name": "RateLimitRule",
      "action": "BLOCK",
      "condition": "requests > 1000 per 5 minutes"
    },
    {
      "name": "SQLInjectionRule",
      "action": "BLOCK",
      "condition": "SQL injection patterns"
    },
    {
      "name": "XSSRule",
      "action": "BLOCK", 
      "condition": "XSS patterns"
    },
    {
      "name": "IPWhitelistRule",
      "action": "ALLOW",
      "condition": "admin IP addresses"
    }
  ]
}
```

### 6.2 Secrets Management

#### 6.2.1 AWS Secrets Manager
```bash
# シークレット作成
aws secretsmanager create-secret \
    --name "koemo/mongodb" \
    --description "MongoDB connection string" \
    --secret-string "mongodb+srv://user:pass@cluster.mongodb.net/koemo"

aws secretsmanager create-secret \
    --name "koemo/jwt" \
    --description "JWT signing secrets" \
    --secret-string '{"secret":"your-secret","refresh_secret":"your-refresh-secret"}'
```

## 7. バックアップ・災害復旧

### 7.1 バックアップ戦略

#### 7.1.1 MongoDB Atlas バックアップ
```yaml
Backup Configuration:
  Type: Continuous Cloud Backup
  Retention:
    - Hourly: 24 hours
    - Daily: 7 days
    - Weekly: 4 weeks
    - Monthly: 12 months
  
  Point-in-Time Recovery: Enabled
  Geo-distributed: 3 regions
```

#### 7.1.2 アプリケーションデータ
```bash
# 重要データのエクスポート
mongodump --uri="$MONGODB_URI" \
    --collection=users \
    --out=/backup/$(date +%Y%m%d)

# S3へアップロード
aws s3 cp /backup/ s3://koemo-backups/ --recursive
```

### 7.2 災害復旧計画

#### 7.2.1 RTO/RPO 目標
```yaml
Recovery Objectives:
  RTO (Recovery Time Objective): 4 hours
  RPO (Recovery Point Objective): 1 hour
  
Multi-Region Setup:
  Primary: ap-northeast-1 (Tokyo)
  Secondary: us-west-2 (Oregon)
  
Failover Trigger:
  - Regional outage > 1 hour
  - Service degradation > 80%
```

#### 7.2.2 フェイルオーバー手順
```bash
#!/bin/bash
# disaster-recovery.sh

echo "Starting disaster recovery procedure..."

# 1. DNS フェイルオーバー
aws route53 change-resource-record-sets \
    --hosted-zone-id Z123456 \
    --change-batch file://failover-changeset.json

# 2. データベース フェイルオーバー
# MongoDB Atlas automatically handles regional failover

# 3. アプリケーション起動 (セカンダリリージョン)
aws ecs update-service \
    --cluster koemo-disaster-recovery \
    --service koemo-backend-service \
    --desired-count 3 \
    --region us-west-2

echo "Disaster recovery completed"
```

## 8. スケーリング

### 8.1 水平スケーリング

#### 8.1.2 Auto Scaling 設定
```yaml
ECS Auto Scaling:
  Target Tracking:
    - Metric: CPU Utilization
      Target: 70%
    - Metric: Memory Utilization  
      Target: 80%
  
  Step Scaling:
    Scale Out:
      - CPU > 80% for 2 minutes: +2 tasks
      - CPU > 90% for 1 minute: +3 tasks
    Scale In:
      - CPU < 50% for 5 minutes: -1 task

Application Load Balancer:
  Connection Draining: 300 seconds
  Health Check Grace Period: 60 seconds
```

### 8.2 データベーススケーリング

#### 8.2.1 MongoDB Atlas スケーリング
```yaml
Cluster Scaling:
  Current: M30 (2 vCPU, 8GB RAM)
  
  Auto-scaling Triggers:
    - CPU > 80%: Upgrade to M40
    - Storage > 80%: Add 20GB
    - Connections > 1000: Add replica
  
  Read Replicas:
    - Primary: 1 node
    - Secondary: 2 nodes
    - Analytics: 1 node (optional)
```

## 9. 運用手順

### 9.1 日常運用タスク

#### 9.1.1 毎日の確認項目
```bash
#!/bin/bash
# daily-health-check.sh

echo "=== Daily Health Check $(date) ==="

# 1. サービス状態確認
aws ecs describe-services \
    --cluster koemo-production \
    --services koemo-backend-service \
    --query 'services[0].runningCount'

# 2. エラーログ確認
aws logs filter-log-events \
    --log-group-name /ecs/koemo-backend \
    --start-time $(date -d "1 day ago" +%s)000 \
    --filter-pattern "ERROR"

# 3. パフォーマンスメトリクス
aws cloudwatch get-metric-statistics \
    --namespace AWS/ApplicationELB \
    --metric-name TargetResponseTime \
    --start-time $(date -d "1 day ago" -u +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 3600 \
    --statistics Average

# 4. データベース接続確認
mongosh "$MONGODB_URI" --eval "db.runCommand({ping: 1})"

echo "Health check completed"
```

#### 9.1.2 週次メンテナンス
```bash
#!/bin/bash
# weekly-maintenance.sh

echo "=== Weekly Maintenance $(date) ==="

# 1. セキュリティアップデート確認
aws ssm describe-instance-patch-states

# 2. ログローテーション
aws logs describe-log-groups \
    --query 'logGroups[?retentionInDays==`null`]'

# 3. 不要なECRイメージ削除
aws ecr list-images \
    --repository-name koemo-backend \
    --filter tagStatus=UNTAGGED

# 4. バックアップ確認
aws s3 ls s3://koemo-backups/ --recursive

echo "Weekly maintenance completed"
```

### 9.2 緊急時対応

#### 9.2.1 サービス障害対応
```yaml
Incident Response Procedure:

1. 検知 (Detection):
   - CloudWatch アラート
   - ユーザー報告
   - 監視ツール

2. 初動対応 (First Response):
   - インシデント管理者指名
   - 影響範囲確認
   - ステータスページ更新

3. 調査・復旧 (Investigation & Recovery):
   - ログ分析
   - メトリクス確認
   - 復旧作業実行

4. 事後対応 (Post-Incident):
   - ポストモーテム作成
   - 再発防止策検討
   - プロセス改善
```

#### 9.2.2 ロールバック手順
```bash
#!/bin/bash
# rollback.sh

CLUSTER_NAME="koemo-production"
SERVICE_NAME="koemo-backend-service"
PREVIOUS_TASK_DEF=$1

if [ -z "$PREVIOUS_TASK_DEF" ]; then
    echo "Usage: $0 <previous-task-definition-arn>"
    exit 1
fi

echo "Rolling back to: $PREVIOUS_TASK_DEF"

# サービス更新
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --task-definition $PREVIOUS_TASK_DEF

# 完了待ち
aws ecs wait services-stable \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME

echo "Rollback completed"
```

## 10. コスト最適化

### 10.1 リソース最適化

#### 10.1.1 コスト監視
```yaml
Cost Monitoring:
  Budgets:
    - Monthly: $500
    - Quarterly: $1,400
    - Annual: $5,000
  
  Alerts:
    - 80% budget: Warning
    - 90% budget: Critical
    - 100% budget: Automatic action

Reserved Instances:
  - RDS: 1 year term (30% savings)
  - ElastiCache: 1 year term (25% savings)
```

#### 10.1.2 自動シャットダウン
```bash
# 開発環境の自動停止 (平日 20:00)
0 20 * * 1-5 aws ecs update-service \
    --cluster koemo-development \
    --service koemo-backend-dev \
    --desired-count 0
```

## 11. チェックリスト

### 11.1 デプロイ前チェック
- [ ] 全テストが成功している
- [ ] セキュリティスキャンが完了している
- [ ] データベースマイグレーションが確認済み
- [ ] 環境変数が正しく設定されている
- [ ] バックアップが最新状態
- [ ] 監視・アラートが有効
- [ ] ロールバック手順が準備済み

### 11.2 デプロイ後チェック
- [ ] ヘルスチェックエンドポイントが正常
- [ ] アプリケーションログにエラーがない
- [ ] メトリクスが正常範囲内
- [ ] CDN キャッシュが更新されている
- [ ] DNS の伝播が完了している
- [ ] 外部サービス連携が正常

---

本手順書に従って、KOEMOアプリケーションの安全で信頼性の高いデプロイメントと継続的な運用を実現します。