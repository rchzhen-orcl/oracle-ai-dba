# Oracle AI DBA Assistant

Локальный AI-ассистент для Oracle Database на основе Ollama и Qwen.

## Возможности

- Сбор метрик из V$WAITCLASSMETRIC
- Обнаружение аномалий
- Анализ с помощью локальной модели Qwen
- Сохранение рекомендаций в Oracle

## Состав проекта

sql/
- tele_graf.sql
- tele_graf_all.sql
- tele_graf_history.sql
- tele_graf_alerts.sql
- refresh_tele_graf_history.sql

python/
- ora_ollama.py

## Требования

- Oracle Database
- Python 3
- Ollama
- Qwen2.5

## Статья

Подробное описание проекта опубликовано на Habr.
