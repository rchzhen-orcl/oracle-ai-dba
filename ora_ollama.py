import json
import oracledb
import requests

# Настройки те же
DB_USER = "*****"
DB_PASSWORD = "*****"
DB_DSN = "*****"
OLLAMA_URL = "*****"

OLLAMA_URL = "*****"
# Важно: имя должно совпадать с тем, что выводит команда `ollama list`
MODEL_NAME = "qwen2.5:3b" 



def check_and_save_alert():
    try:
        connection = oracledb.connect(user=DB_USER, password=DB_PASSWORD, dsn=DB_DSN)
        cursor = connection.cursor()
    except Exception as db_err:
        print(f"Ошибка подключения к Oracle: {db_err}")
        return

    # ТЕСТОВЫЙ ЗАПРОС: берем самую последнюю строку без привязки ко времени
    query_metrics = """
        SELECT TO_CHAR(end_time, 'YYYY-MM-DD HH24:MI:SS') as dt,
               t_userio, t_concurrency, t_systemio, t_commit,
               p_userio, p_concurrency, p_systemio, p_commit
        FROM tele_graf_history
        WHERE end_time >= SYSTIMESTAMP - INTERVAL '30' MINUTE
        ORDER BY end_time DESC
    """
    
    try:
        cursor.execute(query_metrics)
        columns = [col.name.lower() for col in cursor.description]
        raw_rows = cursor.fetchall()
        
        if not raw_rows:
            print("Инфо: В таблице tele_graf_history вообще нет записей. Нечего анализировать.")
            return 

        # ИСПРАВЛЕНИЕ: берем первый элемент списка raw_rows[0], который является кортежем данных!
        latest_anomaly = dict(zip(columns, raw_rows[0]))
        anomaly_time = latest_anomaly['dt']

        # ПРОВЕРЯЕМ НАЛИЧИЕ ДУБЛИКАТОВ
        check_alert_query = """
            SELECT 1 FROM tele_graf_alerts 
            WHERE alert_time = TO_TIMESTAMP(:1, 'YYYY-MM-DD HH24:MI:SS')
        """
        cursor.execute(check_alert_query, [anomaly_time])
        if cursor.fetchone():
            print(f"Инфо: Отчет для метки времени {anomaly_time} уже сохранен в базе (tele_graf_alerts).")
            return

        # ПРОМПТ ДЛЯ QWEN 2.5
        compact_json = json.dumps(latest_anomaly)
        
        prompt = f"""
Ты — ведущий инженер производительности СУБД Oracle (Senior DBA Performance Tuning). 
В базе данных зафиксирована критическая аномалия производительности!

Время сбоя: {anomaly_time}
Метрики (t_ - абсолютное время ожидания, p_ - процент от общего DB Time):
{compact_json}

Проанализируй эти данные и дай экстренное заключение для администратора строго по пунктам:
1. Что сломалось (Главный Bottleneck)?
2. Срочное действие для исправления ситуации (какую SQL-команду выполнить или что проверить).

Отвечай кратко, тезисно, на русском языке. Без лишних вступлений.
"""

        payload = {
            "model": MODEL_NAME,
            "prompt": prompt,
            "stream": False,
            "options": {"temperature": 0.1}
        }

        print(f"Обнаружена аномалия за {anomaly_time}. Отправка запроса в Ollama ({MODEL_NAME})...")
        
        response = requests.post(OLLAMA_URL, json=payload, timeout=45)
        response.raise_for_status()
        result_json = response.json()
        
        ai_text = result_json.get("response", "").strip()
        
        if not ai_text:
            ai_text = "Ошибка: Нейросеть вернула пустой ответ."

        print("\n=== !!! ОБНАРУЖЕНА АНОМАЛИЯ В СУБД !!! ===")
        print(ai_text)
        print("===========================================\n")

        # ЗАПИСЫВАЕМ ОТЧЕТ ОБРАТНО В ORACLE
        insert_query = """
            INSERT INTO tele_graf_alerts (alert_time, raw_metrics, ai_analysis)
            VALUES (TO_TIMESTAMP(:1, 'YYYY-MM-DD HH24:MI:SS'), :2, :3)
        """
        cursor.execute(insert_query, [anomaly_time, compact_json, ai_text])
        connection.commit()
        print(f"Экстренный анализ успешно сохранен в таблицу tele_graf_alerts.")

    except Exception as e:
        print(f"Критическая ошибка при выполнении скрипта: {e}")
        
    finally:
        cursor.close()
        connection.close()


if __name__ == "__main__":
    check_and_save_alert()
