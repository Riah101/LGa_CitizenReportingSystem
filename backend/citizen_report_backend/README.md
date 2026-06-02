# Sauti ya Raia — Django REST API Backend

Tanzania Citizen Complaint & Escalation Platform — Backend

---

## 🏗️ Project Structure

```
citizen_report_backend/
├── config/
│   ├── settings.py          # Django settings
│   ├── urls.py              # Root URL config
│   ├── celery.py            # Celery + beat schedule
│   └── wsgi.py
│
├── apps/
│   ├── users/               # Auth & user management
│   │   ├── models.py        # User, OTPCode
│   │   ├── serializers.py   # Register, Login, OTP
│   │   ├── views/
│   │   │   ├── auth_views.py    # Login, Register, OTP, Me
│   │   │   └── user_views.py    # Profile, Stats, List
│   │   ├── urls/
│   │   │   ├── auth_urls.py
│   │   │   └── user_urls.py
│   │   ├── permissions.py   # Custom DRF permissions
│   │   ├── tasks.py         # OTP cleanup, SMS
│   │   ├── signals.py
│   │   └── admin.py
│   │
│   ├── complaints/          # Core complaint system
│   │   ├── models.py        # Complaint, EscalationHistory, Comment...
│   │   ├── serializers.py   # List, Detail, Create, Comment
│   │   ├── views.py         # CRUD + escalate/resolve/upvote
│   │   ├── filters.py       # ComplaintFilter
│   │   ├── tasks.py         # auto_escalate_complaints (Celery)
│   │   ├── urls.py
│   │   ├── signals.py
│   │   └── admin.py
│   │
│   └── notifications/       # User notification system
│       ├── models.py        # Notification
│       ├── serializers.py
│       ├── views.py         # List, mark read, count
│       ├── tasks.py         # Async notification delivery
│       ├── urls.py
│       ├── admin.py
│       └── apps.py
│
├── scripts/
│   ├── setup.sh             # One-command setup
│   └── seed_data.py         # Demo data
│
├── manage.py
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
└── .env.example
```

---

## ⚡ Quick Start (Without Docker)

### 1. Prerequisites
- Python 3.11+
- PostgreSQL 14+
- Redis 7+

### 2. PostgreSQL Setup
```sql
-- In psql:
CREATE DATABASE citizen_report_db;
CREATE USER postgres WITH PASSWORD 'yourpassword';
GRANT ALL PRIVILEGES ON DATABASE citizen_report_db TO postgres;
```

### 3. Project Setup
```bash
cd citizen_report_backend

# Create & activate virtual environment
python -m venv venv
venv\Scripts\activate        # Windows
source venv/bin/activate     # Linux/Mac

# Install dependencies
pip install -r requirements.txt

# Configure environment
copy .env.example .env       # Windows
cp .env.example .env         # Linux/Mac
# Edit .env with your DB credentials

# Run migrations
python manage.py makemigrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Load demo data
python manage.py shell -c "from scripts.seed_data import seed; seed()"

# Start server
python manage.py runserver
```

### 4. Start Celery (separate terminals)
```bash
# Worker
celery -A config worker -l info

# Beat scheduler (auto-escalation cron)
celery -A config beat -l info --scheduler django_celery_beat.schedulers:DatabaseScheduler
```

---

## 🐳 Quick Start (Docker - Recommended)

```bash
# Copy env file
cp .env.example .env

# Build and start all services
docker-compose up --build

# In another terminal, create superuser
docker-compose exec web python manage.py createsuperuser

# Load demo data
docker-compose exec web python manage.py shell -c "from scripts.seed_data import seed; seed()"
```

---

## 📡 API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/api/v1/auth/register/` | ❌ | Register new citizen |
| `POST` | `/api/v1/auth/login/` | ❌ | Login → JWT tokens |
| `POST` | `/api/v1/auth/logout/` | ✅ | Blacklist refresh token |
| `POST` | `/api/v1/auth/token/refresh/` | ❌ | Refresh access token |
| `GET`  | `/api/v1/auth/me/` | ✅ | Current user profile |
| `POST` | `/api/v1/auth/otp/request/` | ❌ | Request phone OTP |
| `POST` | `/api/v1/auth/otp/verify/` | ❌ | Verify phone OTP |
| `POST` | `/api/v1/auth/change-password/` | ✅ | Change password |
| | | | |
| `GET`  | `/api/v1/users/profile/` | ✅ | Get/update profile |
| `GET`  | `/api/v1/users/stats/` | ✅ | Complaint stats for user |
| | | | |
| `GET`  | `/api/v1/complaints/` | ✅ | List complaints (role-filtered) |
| `POST` | `/api/v1/complaints/` | ✅ | Submit new complaint |
| `GET`  | `/api/v1/complaints/<id>/` | ✅ | Complaint detail |
| `PATCH`| `/api/v1/complaints/<id>/` | ✅ Officer | Update status |
| `POST` | `/api/v1/complaints/<id>/escalate/` | ✅ Officer | Manual escalate |
| `POST` | `/api/v1/complaints/<id>/resolve/` | ✅ Officer | Mark resolved |
| `POST` | `/api/v1/complaints/<id>/upvote/` | ✅ | Toggle upvote |
| `POST` | `/api/v1/complaints/<id>/comment/` | ✅ | Add comment |
| `POST` | `/api/v1/complaints/<id>/attachment/` | ✅ | Upload file |
| `GET`  | `/api/v1/complaints/track/?code=SR4K9X` | ❌ | Public tracking |
| `GET`  | `/api/v1/complaints/public/` | ❌ | Public feed |
| `GET`  | `/api/v1/complaints/stats/` | ✅ | Dashboard stats |
| | | | |
| `GET`  | `/api/v1/notifications/` | ✅ | List notifications |
| `GET`  | `/api/v1/notifications/unread-count/` | ✅ | Unread count |
| `POST` | `/api/v1/notifications/mark-all-read/` | ✅ | Mark all read |
| `POST` | `/api/v1/notifications/<id>/read/` | ✅ | Mark one read |
| `DELETE`| `/api/v1/notifications/clear/` | ✅ | Clear read notifications |
| | | | |
| `GET`  | `/api/docs/` | ❌ | Swagger UI |
| `GET`  | `/api/redoc/` | ❌ | ReDoc |

---

## 🔐 Authentication Flow

```
1. POST /api/v1/auth/register/  → { access, refresh, user }
2. POST /api/v1/auth/login/     → { access, refresh, user }
3. Include header: Authorization: Bearer <access_token>
4. POST /api/v1/auth/token/refresh/ when access expires → { access }
```

---

## ⚙️ Escalation Schedule (Auto via Celery Beat)

| Level     | Days Before Escalation |
|-----------|------------------------|
| Mtaa      | **7 days**             |
| Ward/Kata | **14 days**            |
| District  | **21 days**            |
| Region    | **30 days**            |
| National  | Final level            |

Cron runs daily at **midnight (Africa/Dar_es_Salaam)**.
Warning notifications sent daily at **8:00 AM** for complaints escalating in 1-2 days.

---

## 👥 Demo Accounts (after seeding)

| Role | Phone | Password |
|------|-------|----------|
| Admin | +255000000000 | admin123 |
| Citizen | +255711111111 | citizen123 |
| Citizen | +255722222222 | citizen123 |
| Mtaa Officer | +255700000001 | officer123 |
| Ward Officer | +255700000002 | officer123 |
| District Officer | +255700000003 | officer123 |
| Region Officer | +255700000004 | officer123 |
| National Officer | +255700000005 | officer123 |

---

## 🔌 Flutter Integration

Update your Flutter `ComplaintProvider` base URL:

```dart
// In lib/services/api_service.dart
const String baseUrl = 'http://10.0.2.2:8000/api/v1';  // Android emulator
const String baseUrl = 'http://localhost:8000/api/v1';  // Web/Desktop
```

---

*Built for Tanzania 🇹🇿 · Django 5 · PostgreSQL 16 · Redis 7 · Celery 5*
