FROM python:3.10-slim

RUN apt-get update && apt-get install -y curl

WORKDIR /app
COPY . .
RUN pip install -r requirements.txt

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]

