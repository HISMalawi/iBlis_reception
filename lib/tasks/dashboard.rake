namespace :dashboard do
  desc "TODO"
  task fetch_stats: :environment do
      puts Time.now.to_s(:db)
      require 'json'
      file_name = "/tmp/orders"

      Test.find_by_sql(
          "SELECT t.id AS test_id,
                  p.name,
                  p.external_patient_number,
                  v.ward_or_location,
                  s.accession_number,
                  (SELECT name FROM specimen_types WHERE id = s.specimen_type_id) AS specimen_type,
                  (SELECT name FROM specimen_statuses WHERE id = s.specimen_status_id) AS specimen_status,
                  (SELECT name FROM test_statuses WHERE id = t.test_status_id) AS test_status,
                  (SELECT name FROM test_types WHERE id = t.test_type_id) AS test_type,
                  t.requested_by,
                  COALESCE(t.panel_id, ''),
                  (SELECT name FROM test_categories WHERE id = (SELECT test_category_id FROM test_types WHERE id = t.test_type_id)) AS department,
                  COALESCE(s.time_rejected, t.time_verified, t.time_completed, t.time_started, t.time_created) time_updated

            FROM tests t

              INNER JOIN specimens s ON t.specimen_id = s.id
              INNER JOIN visits v ON t.visit_id = v.id
              INNER JOIN patients p ON p.id = v.patient_id
            WHERE
                (
                  t.test_status_id IN (SELECT id FROM test_statuses
                            WHERE name in ('not-received', 'pending', 'started', 'completed')
                          )
                  OR
                  (t.test_status_id IN (SELECT id FROM test_statuses
                            WHERE name in ('verified')
                          ) AND TIMESTAMPDIFF(HOUR, t.time_verified, CURDATE()) <= 36
                  )
                )
                AND
                (
                  s.specimen_status_id IN (SELECT id FROM specimen_statuses
                              WHERE name IN ('specimen-accepted', 'specimen-not-collected')
                            )
                  OR
                  (s.specimen_status_id IN (SELECT id FROM specimen_statuses
                              WHERE name IN ('specimen-rejected')
                            ) AND TIMESTAMPDIFF(HOUR, s.time_rejected, CURDATE()) <= 8
                  )
                )
            ORDER BY time_updated DESC

                INTO OUTFILE '#{file_name}.tmp'
                FIELDS TERMINATED BY ','
                ENCLOSED BY '\"'
                LINES TERMINATED BY '\n'
          "
      )

      Test.find_by_sql(
          "SELECT  (SELECT name FROM specimen_statuses
                        WHERE id = s.specimen_status_id) AS specimen_status,
                  (SELECT name FROM test_statuses
                        WHERE id = t.test_status_id) AS test_status,
                  COUNT(*) count

                FROM specimens s
                  INNER JOIN tests t ON s.id = t.specimen_id
                GROUP BY s.specimen_status_id, t.test_status_id

                INTO OUTFILE '#{file_name}_aggregates.tmp'
                FIELDS TERMINATED BY ','
                ENCLOSED BY '\"'
                LINES TERMINATED BY '\n'
          "
      )

    `mv #{file_name}.tmp #{file_name}.csv`
    `mv #{file_name}_aggregates.tmp #{file_name}_aggregates.csv`
end

end
