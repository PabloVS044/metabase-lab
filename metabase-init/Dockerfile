FROM python:3.12-slim
RUN pip install requests --no-cache-dir
WORKDIR /app
COPY init.py .
CMD ["python", "init.py"]
