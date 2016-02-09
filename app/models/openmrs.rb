class Openmrs < ActiveRecord::Base

  self.abstract_class = true

  establish_connection(:openmrs)

  def self.search_by_npid(npid)
    results = connection.select_all(
																			"SELECT '0' AS patient_number , pid.identifier AS external_patient_number,
                                            CONCAT(COALESCE(pn.given_name, ''), ' ',
                                            COALESCE(pn.middle_name, ''),  ' ',
                                            COALESCE(pn.family_name, '')) AS name,
                                            p.gender,
                                            p.birthdate AS dob,
                                            pa.city_village AS address
                                            FROM patient_identifier pid
                                      INNER JOIN person_name pn ON pid.patient_id = pn.person_id AND pn.voided = 0
                                      INNER JOIN person_address pa ON pa.person_id = pn.person_id AND pa.voided = 0
                                      INNER JOIN person p ON pid.patient_id = p.person_id AND p.voided = 0
                                      WHERE pid.voided = 0 AND pid.identifier = '#{npid}'
                                      "
		)
    results
  end

end
