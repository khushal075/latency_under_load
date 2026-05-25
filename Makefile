.PHONY: start stop sync async db clean

# Start everything (apps + db later)
start:
	@echo "🚀 Starting all services..."
	@make db &
	@sleep 2
	@make sync &
	@make async &
	@wait

# Start sync app
sync:
	@echo "🔥 Starting sync app on 8001"
	bash scripts/sync/gunicorn_1.sh

# Start async app
async:
	@echo "⚡ Starting async app on 8002"
	bash scripts/async/uvicorn_1.sh

# Placeholder for DB (we’ll replace with Docker later)
db:
	@echo "🗄️ Starting DB (placeholder)"
	@echo "⚠️ Make sure Postgres is running"

# Stop everything (manual for now)
stop:
	@echo "🛑 Stop services manually (Ctrl+C)"

clean:
	@echo "🧹 Cleaning..."
	rm -rf */__pycache__