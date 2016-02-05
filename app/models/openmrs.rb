class Openmrs < ActiveRecord::Base

  self.abstract_class = true

  establish_connection(:openmrs)

  def self.search_by_npid(npid)
    results = connection.select_all(
																			"SELECT pid.identifier, pn.given_name, pn.family_name, pn.middle_name,
                                            p.gender, p.birthdate
                                            FROM patient_identifier pid
                                      INNER JOIN person_name pn ON pid.patient_id = pn.person_id AND pn.voided = 0
                                      INNER JOIN person p ON pid.patient_id = p.person_id AND p.voided = 0
                                      WHERE pid.voided = 0 AND pid.identifier = '#{npid}'
                                      "
		)
    results
  end

end
