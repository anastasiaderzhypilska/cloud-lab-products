# Cloud Lab — Products REST API

Лабораторна робота №1. Розгортання REST API у хмарі AWS.

## Застосунок
Python FastAPI + PostgreSQL. API підтримує роботу з товарами.

- GET /health — перевірка стану
- /products — операції з товарами
- /docs — Swagger UI

## Публічна адреса
http://cloud-lab-alb-1682586168.eu-north-1.elb.amazonaws.com

## Технології
Docker, Docker Compose, Terraform, AWS ECR, ECS Fargate, RDS PostgreSQL, ALB, Secrets Manager, IAM, CloudWatch, GitHub Actions.

## Архітектура
Internet → ALB → ECS Fargate → RDS PostgreSQL

RDS знаходиться у приватних підмережах. ECS отримує DATABASE_URL через AWS Secrets Manager.

## Локальний запуск
Створити .env з необхідними змінними, потім:

    docker compose up -d --build

Swagger: http://localhost:8000/docs

Зупинка:

    docker compose down

## Terraform
Конфігурація знаходиться в terraform/.

    cd terraform
    terraform init
    terraform validate
    terraform plan
    terraform apply

Перед запуском потрібні AWS credentials, db_password та Docker-образ в ECR.

Видалення інфраструктури після захисту:

    terraform destroy

Terraform state містить конфіденційні дані й не завантажується в Git.

## CI/CD
Workflow: .github/workflows/deploy.yml

Після push у main GitHub Actions:
1. Авторизується в AWS через OIDC.
2. Збирає Docker-образ.
3. Завантажує образ в ECR з тегом Git SHA.
4. Оновлює ECS Task Definition та ECS Service.
5. Очікує стабілізації сервісу.

## Безпека
- RDS не має публічного доступу.
- Пароль PostgreSQL не зберігається в Git.
- Secrets Manager передає DATABASE_URL в ECS.
- GitHub Actions використовує OIDC без постійних AWS-ключів.
- Контейнер працює без root.
