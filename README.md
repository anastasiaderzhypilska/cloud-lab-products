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

## Перше розгортання з нуля

Потрібні Docker, Terraform, AWS CLI та налаштовані AWS credentials.
Перед запуском налаштувати MFA, AWS Budget і пароль БД у
terraform/database.auto.tfvars (цей файл не додавати в Git).

1. Створити ECR:

    cd terraform
    terraform init
    terraform apply -target=aws_ecr_repository.api

2. Повернутися в корінь проєкту й завантажити образ:

    cd ..
    export AWS_PROFILE=cloud-lab-admin
    export AWS_REGION=eu-north-1
    export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    export ECR="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/cloud-lab-products"

    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
    docker build -t "$ECR:v1" .
    docker push "$ECR:v1"

3. Завершити створення інфраструктури:

    cd terraform
    terraform apply

Після першого розгортання GitHub Actions автоматично оновлює ECS
при кожному push у main.

Видалення після захисту: terraform destroy.

## Структура проєкту

- `app/` — вихідний код FastAPI.
- `Dockerfile` — збірка Docker-образу API.
- `compose.yaml` — локальний запуск API та PostgreSQL.
- `requirements.txt` — залежності Python.
- `terraform/` — інфраструктура AWS як код.
- `.github/workflows/deploy.yml` — автоматичний CI/CD.

## Налаштування локального середовища

У корені проєкту створити файл `.env`:

    DB_PASSWORD=local_password_123

Це приклад пароля лише для локальної розробки. Не використовувати
його як пароль AWS RDS.

Запуск:

    docker compose up -d --build

Перевірка:

    curl http://localhost:8000/health

Зупинка зі збереженням даних PostgreSQL:

    docker compose down

Дані залишаються у Docker volume `pgdata`.

## JWT-автентифікація

Ендпоінти для роботи з товарами захищені JWT:

- GET /products
- POST /products
- PUT /products/{product_id}
- DELETE /products/{product_id}

Для доступу необхідний заголовок:
Authorization: Bearer <JWT_TOKEN>

Токен перевіряється сервером за алгоритмом HS256.
Без токена API повертає HTTP 401 Unauthorized.

Ендпоінти /health і /docs доступні без авторизації.

Для локального запуску файл .env повинен містити:

    DB_PASSWORD=<local_database_password>
    JWT_SECRET=<random_secret>

Для AWS секрет JWT зберігається в Secrets Manager.
Перед першим terraform apply необхідно створити
в корені проєкту файл .jwt_secret з випадковим секретом.
Файл .jwt_secret не додається в Git.

## Моніторинг AWS

Моніторинг описаний у terraform/monitoring.tf.

CloudWatch Logs:
- /ecs/cloud-lab-products

CloudWatch Dashboard:
- cloud-lab-dashboard
- HTTP Requests
- HTTP 5xx Errors
- Response Time
- ECS CPU and Memory

CloudWatch Alarm:
- cloud-lab-api-5xx
- Спрацьовує, якщо протягом 5 хвилин є помилки HTTP 5xx.

Amazon SNS:
- Topic: cloud-lab-alerts
- Email-підписка потребує підтвердження через лист AWS.

Email задається через змінну Terraform alert_email.
