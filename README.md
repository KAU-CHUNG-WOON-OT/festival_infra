# infra

축제 플랫폼(festival) AWS 인프라 — Terraform IaC 저장소.

VPC, ALB, ECS Fargate(3개 마이크로서비스), RDS MySQL, ECR, CloudWatch 모니터링, Bastion을 모듈 단위로 구성하여 `dev` / `prod` 환경으로 배포합니다.

## 아키텍처 개요

```
Internet
   │
   ▼
  ALB (HTTPS:443, HTTP→HTTPS 리다이렉트)
   ├─ /swagger-ui*, /v3/api-docs*, /oauth2/*, /login/oauth2/*, /auth/*, /api/*  → Main Service   (:8080)
   ├─ /api/votes*                                                              → Vote Service   (:8081)
   └─ /ticket/*, /docs, /openapi.json, /redoc, /health                         → Ticket Query    (:8000)
   │
   ▼
ECS Fargate Cluster (festival-{env}-cluster)
   ├─ Main Service          (Spring Boot, Java)
   ├─ Vote Service          (Spring Boot, Java, 투표 기간 스케줄 스케일링)
   └─ Ticket Query Service  (FastAPI 등, DynamoDB + RDS 조회)
   │
   ▼
RDS MySQL 8.0 (festival-{env}-db, private subnet)

Bastion EC2 (public subnet) → SSH 터널로 RDS 접근
```

모든 서비스는 private subnet에 배치되고, NAT Gateway를 통해 아웃바운드 인터넷에 접근합니다. RDS는 Main/Vote/Ticket 서비스와 Bastion에서만 3306 포트로 접근 가능합니다.

## 리포지토리 구조

```
.
├── main.tf                 # 루트 모듈 — 전체 서비스 조합
├── variables.tf            # 루트 입력 변수
├── outputs.tf              # 루트 출력값 (ALB DNS, ECR URL, DB endpoint 등)
├── versions.tf             # Terraform/AWS 프로바이더 버전, 리전(ap-northeast-2)
├── backend.tf              # S3 + DynamoDB 원격 상태 백엔드
├── environments/
│   ├── dev/terraform.tfvars    # 개발 환경 변수값 (커밋 대상 아님, gitignore 처리)
│   └── prod/terraform.tfvars   # 운영 환경 변수값 (커밋 대상 아님, gitignore 처리)
└── modules/
    ├── networking/      # VPC, 퍼블릭/프라이빗 서브넷(2개 AZ), IGW, NAT, 라우팅 테이블, 보안그룹
    ├── alb/              # ALB, 리스너(80/443), 타겟그룹 3개, 경로 기반 리스너 룰
    ├── ecs-cluster/     # ECS 클러스터(Fargate), CloudWatch 로그 그룹, 실행/태스크 IAM 롤
    ├── ecr/              # ECR 리포지토리(main, vote, ticket-query), 라이프사이클 정책
    ├── database/        # RDS MySQL 8.0, 파라미터 그룹, 서브넷 그룹
    ├── service-main/    # Main 서비스 ECS 태스크/서비스, SSM 파라미터, 오토스케일링
    ├── service-vote/    # Vote 서비스 ECS 태스크/서비스, 스케줄 스케일링, ALB 요청수 기반 스케일링
    ├── service-ticket/  # Ticket Query 서비스 ECS 태스크/서비스
    ├── bastion/          # SSH 접속용 EC2 (Amazon Linux 2023) + EIP
    └── monitoring/      # SNS 알람, CloudWatch 메트릭 알람 3종, 대시보드
```

## 주요 모듈 설명

### networking
- VPC(`10.0.0.0/16`), 퍼블릭 서브넷 2개(2a/2c), 프라이빗 서브넷 2개(2a/2c)
- 단일 NAT Gateway(public-2a에 배치)
- 보안그룹: `sg-alb`(80/443 인바운드), `sg-main`(8080, ALB만), `sg-vote`(8081, ALB만), `sg-ticket`(8000, ALB만), `sg-bastion`(22, 전체 오픈), `sg-db`(3306, main/vote/ticket/bastion만)

### alb
- HTTP(80) → HTTPS(443) 리다이렉트, TLS 1.3 정책 적용
- 기본 응답은 404 fixed-response, 경로 기반 리스너 룰로 각 서비스 타겟그룹에 라우팅
- Main 타겟그룹은 `lb_cookie` 세션 스티키니스 활성화

### ecs-cluster
- Fargate 전용 클러스터, Container Insights 활성화
- 서비스별 CloudWatch 로그 그룹(`/ecs/festival-{main,vote,ticket-query}`, 14일 보관)
- 실행 롤(ECR pull, SSM 파라미터 조회)과 태스크 롤(CloudWatch 커스텀 메트릭, DynamoDB 티켓/카운터 테이블 접근) 분리

### database
- RDS MySQL 8.0 단일 인스턴스(`db.t4g.small`, `gp3` 20GB, 암호화)
- Slow query 로그(2초 이상) CloudWatch Logs로 전송, 백업/유지보수 윈도우 지정
- 비밀번호는 `lifecycle.ignore_changes`로 상태 드리프트 방지(외부에서 회전 가능)

### service-main / service-vote / service-ticket
- 각각 별도 ECR 리포지토리 이미지로 Fargate 태스크 정의 및 서비스 구성
- DB 비밀번호, Swagger/Docs 비밀번호, JWT Secret은 SSM Parameter Store(SecureString)를 통해 주입
- 배포 서킷 브레이커 및 오토스케일링(CPU 타겟 트래킹 등) 구성
- **Vote 서비스**는 투표 이벤트 특성에 맞춰 스케줄 기반 스케일아웃/인(`aws_appautoscaling_scheduled_action`, cron은 UTC 기준이며 실제 운영 시간표에 맞게 수정 필요)과 ALB 요청수 기반 타겟 트래킹 스케일링을 함께 사용

### bastion
- Amazon Linux 2023 `t3.micro` EC2, 퍼블릭 서브넷에 EIP 할당
- IntelliJ 등에서 SSH 터널로 RDS(private subnet)에 접근하는 용도

### monitoring
- SNS 알람 토픽(이메일 구독은 `alarm_email` 지정 시에만 생성)
- CloudWatch 알람 3종: Main 서비스 CPU 80% 초과, Vote 서비스 5xx 분당 10건 초과, RDS 커넥션 50 초과
- ECS CPU/메모리, ALB 요청수/5xx, 응답시간(p99), RDS 커넥션을 보여주는 대시보드

## 사전 요구사항

- Terraform >= 1.5
- AWS 프로바이더 `~> 5.0`
- 리전: `ap-northeast-2` (서울)
- 원격 상태 백엔드: S3 버킷 `festival-terraform-state-236451048000-apne2` + DynamoDB 락 테이블 `festival-terraform-lock`
- AWS 자격 증명(적절한 IAM 권한)이 설정되어 있어야 함

## 사용법

```bash
# 초기화
terraform init

# dev 환경 계획/적용
terraform plan  -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars

# prod 환경 계획/적용
terraform plan  -var-file=environments/prod/terraform.tfvars
terraform apply -var-file=environments/prod/terraform.tfvars
```

`environments/{dev,prod}/terraform.tfvars`는 비밀번호 등 민감 정보를 포함하므로 `.gitignore`에 의해 저장소에 커밋되지 않습니다. 각자 로컬에 별도로 준비해야 합니다.

### 주요 입력 변수 (루트 `variables.tf`)

| 변수 | 설명 | 기본값 |
| --- | --- | --- |
| `project_name` | 리소스 이름 접두사 | `festival` |
| `environment` | 배포 환경 (`dev`/`prod`) | `dev` |
| `vpc_cidr` | VPC CIDR | `10.0.0.0/16` |
| `domain_name` | 서비스 도메인 | (필수) |
| `certificate_arn` | ALB HTTPS용 ACM 인증서 ARN | (필수) |
| `db_password` | RDS 마스터 비밀번호 | (필수, sensitive) |
| `db_backup_retention_period` | RDS 백업 보관 일수 (0~35) | `7` |
| `alarm_email` | CloudWatch 알람 수신 이메일 | `""` (미구독) |
| `bastion_key_name` | Bastion EC2 키페어 이름 | (필수) |
| `jwt_secret` | Ticket Query 서비스 JWT 시크릿 | (필수, sensitive) |
| `app_base_url` | OAuth2 리다이렉트 등에 쓰이는 앱 베이스 URL | (필수) |
| `swagger_username` / `swagger_password` | Main 서비스 Swagger Basic Auth | `admin` / (필수, sensitive) |

### 주요 출력값 (루트 `outputs.tf`)

- `alb_dns_name` — Route53 ALIAS 레코드 대상
- `ecs_cluster_name`
- `ecr_main_repo_url`, `ecr_vote_repo_url`
- `db_endpoint` (sensitive)
- `bastion_public_ip` — SSH 터널 접속 주소

## 참고 사항

- CI/CD 파이프라인(이미지 빌드/푸시, 태스크 정의 갱신)은 이 저장소 범위 밖이며, 각 서비스 이미지는 ECR에 미리 푸시되어 있어야 합니다(기본 태그 `latest`).
- Vote 서비스의 스케줄 스케일링 cron 표현식은 예시값이므로, 실제 투표 일정에 맞춰 반드시 수정해야 합니다(UTC 기준, KST = UTC+9).
- `service-ticket` 모듈은 DynamoDB 테이블(`festival-ticketing-ticket`, `festival-ticketing-counter`)을 참조하지만 해당 테이블 자체는 이 저장소에서 관리하지 않습니다.
