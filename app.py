from flask import Flask
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)

metrics = PrometheusMetrics(app)

@app.route("/")
def home():
    return "CI/CD Portfolio Project is running!"

@app.route("/health")
def health():
    return {"status": "unhealthy"}, 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
