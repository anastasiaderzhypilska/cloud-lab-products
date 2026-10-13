# Cloud Lab — Products REST API

Лабораторна робота №1. Розгортання REST API у хмарі AWS.

## Застосунок
Python FastAPI + PostgreSQL. API підтримує роботу з товарами.

- GET /health — перевірка стану
- GET /version — версія застосунку та перевірка CI/CD
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

Перед запуском потрібні AWS credentials, db_password та запущений Docker Desktop. Початковий Docker-образ автоматично збирається і завантажується в ECR через Terraform.

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

Потрібні Terraform, запущений Docker Desktop, AWS CLI
та авторизований AWS-профіль `cloud-lab-admin`.

Перед запуском:
- Увімкнути MFA та налаштувати AWS Budget.
- Створити `terraform/database.auto.tfvars` із паролем PostgreSQL.
- Створити `terraform/alerts.auto.tfvars` з email для сповіщень.
- Створити `.jwt_secret` у корені проєкту.

Команди з кореня проєкту:

    terraform -chdir=terraform init
    TMPDIR="$HOME/cloud-lab-tmp" terraform -chdir=terraform apply

Під час першого apply Terraform створює ECR.
Ресурс `terraform_data.ecr_bootstrap` перевіряє наявність образу `v1`.
Якщо образ відсутній, він збирає та завантажує його до запуску ECS.

Після першого розгортання GitHub Actions автоматично
оновлює ECS після push у `main`, використовуючи тег Git SHA.

Для початкового розгортання потрібні локальні Docker та AWS CLI.
Повне розгортання з порожнього акаунта одним apply ще не перевірено.

Після захисту:

    TMPDIR="$HOME/cloud-lab-tmp" terraform -chdir=terraform destroy

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
    JWT_SECRET=replace_with_random_secret

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

JWT-токен генерується окремо; API не має ендпоінта для його видачі.
Токен перевіряється сервером за алгоритмом HS256.
Без токена API повертає HTTP 401 Unauthorized.

Ендпоінти /health, /version і /docs доступні без авторизації.

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
