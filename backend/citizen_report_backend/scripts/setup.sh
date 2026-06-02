#!/bin/bash
# ─────────────────────────────────────────────────────────────────
# Sauti ya Raia - Backend Setup Script
# Run this once after cloning the project
# ─────────────────────────────────────────────────────────────────

set -e  # Exit on any error

echo "================================================"
echo "  Sauti ya Raia - Django Backend Setup"
echo "================================================"

# 1. Create virtual environment
echo ""
echo "[1/7] Creating virtual environment..."
python -m venv venv

# 2. Activate
echo "[2/7] Activating virtual environment..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    source venv/Scripts/activate
else
    source venv/bin/activate
fi

# 3. Install dependencies
echo "[3/7] Installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# 4. Setup .env
echo "[4/7] Setting up environment variables..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "  → .env created. Please edit it with your database credentials."
else
    echo "  → .env already exists, skipping."
fi

# 5. Create logs directory
mkdir -p logs

# 6. Run migrations
echo "[5/7] Running database migrations..."
python manage.py makemigrations users --settings=config.settings 2>/dev/null || true
python manage.py makemigrations complaints --settings=config.settings 2>/dev/null || true
python manage.py makemigrations notifications --settings=config.settings 2>/dev/null || true
python manage.py migrate --settings=config.settings

# 7. Create superuser
echo "[6/7] Creating superuser..."
python manage.py shell -c "
from apps.users.models import User
if not User.objects.filter(phone='+255000000000').exists():
    User.objects.create_superuser(
        phone='+255000000000',
        password='admin123',
        full_name='System Admin',
    )
    print('  → Superuser created: phone=+255000000000, password=admin123')
else:
    print('  → Superuser already exists')
"

# 8. Load demo data
echo "[7/7] Loading demo data..."
python manage.py shell -c "
from scripts.seed_data import seed
seed()
" 2>/dev/null || echo "  → Demo data script not found, skipping."

echo ""
echo "================================================"
echo "  Setup complete!"
echo "================================================"
echo ""
echo "  Start the server:  python manage.py runserver"
echo "  Admin panel:       http://localhost:8000/admin/"
echo "  API docs:          http://localhost:8000/api/docs/"
echo "  API redoc:         http://localhost:8000/api/redoc/"
echo ""
echo "  Superuser: +255000000000 / admin123"
echo ""
