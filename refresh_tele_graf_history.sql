create or replace PROCEDURE refresh_tele_graf_history AS
BEGIN

  ------------------------------------------------------------------
  -- 1. СОХРАНЯЕМ ВСЕ МЕТРИКИ В tele_graf_all
  ------------------------------------------------------------------

  INSERT INTO tele_graf_all (
      end_time,
      t_userio,
      t_concurrency,
      t_systemio,
      t_commit,
      t_network,
      t_application,
      t_configuration,
      t_administrative,
      p_userio,
      p_concurrency,
      p_systemio,
      p_commit,
      p_network
  )
  SELECT
      v.end_time,
      v.t_userio,
      v.t_concurrency,
      v.t_systemio,
      v.t_commit,
      v.t_network,
      v.t_application,
      v.t_configuration,
      v.t_administrative,
      v.p_userio,
      v.p_concurrency,
      v.p_systemio,
      v.p_commit,
      v.p_network
  FROM tele_graf v
  WHERE NOT EXISTS (
      SELECT 1
      FROM tele_graf_all a
      WHERE a.end_time = v.end_time
  );

  ------------------------------------------------------------------
  -- 2. СОХРАНЯЕМ ТОЛЬКО АНОМАЛИИ В tele_graf_history
  ------------------------------------------------------------------

  INSERT INTO tele_graf_history (
      end_time,
      t_userio,
      t_concurrency,
      t_systemio,
      t_commit,
      t_network,
      t_application,
      t_configuration,
      t_administrative,
      p_userio,
      p_concurrency,
      p_systemio,
      p_commit,
      p_network
  )
  SELECT
      v.end_time,
      v.t_userio,
      v.t_concurrency,
      v.t_systemio,
      v.t_commit,
      v.t_network,
      v.t_application,
      v.t_configuration,
      v.t_administrative,
      v.p_userio,
      v.p_concurrency,
      v.p_systemio,
      v.p_commit,
      v.p_network
  FROM tele_graf v
  WHERE
  (
         (v.p_userio > 50 AND v.t_userio > 1000)
      OR (v.p_concurrency > 20 AND v.t_concurrency > 500)
      OR (v.p_systemio > 40 AND v.t_systemio > 1000)
      OR (v.p_commit > 30 AND v.t_commit > 500)
      OR (v.p_network > 20 AND v.t_network > 500)
      OR (v.p_application > 10 AND v.t_application > 500)
      OR (v.p_configuration > 5 AND v.t_configuration > 500)
      OR (v.t_administrative > 0)
  )
  AND NOT EXISTS (
      SELECT 1
      FROM tele_graf_history h
      WHERE h.end_time = v.end_time
  );

  ------------------------------------------------------------------
  -- 3. ОЧИСТКА СТАРЫХ ДАННЫХ
  ------------------------------------------------------------------

  -- Полная история: 3 дня
  DELETE FROM tele_graf_all
  WHERE end_time < SYSTIMESTAMP - INTERVAL '3' DAY;

  -- Аномалии: 14 дней
  DELETE FROM tele_graf_history
  WHERE end_time < SYSTIMESTAMP - INTERVAL '14' DAY;

  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;
