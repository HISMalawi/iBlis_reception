class Openmrs < ActiveRecord::Base

  self.abstract_class = true

  #establish_connection(:openmrs)

  establish_connection(
      Rails.configuration.database_configuration["openmrs"].inject({}){|h, v|
        h[v.first] = (v.last.to_s.length > 40 ? EncryptionWrapper.humanize(v.last) : v.last); h
      })

  def self.search_by_npid(npid)
    results = connection.select_all(
																			"SELECT '0' AS patient_number , pid.identifier AS external_patient_number,
                                            CONCAT(COALESCE(pn.given_name, ''), ' ',
                                            COALESCE(pn.family_name, '')) AS name,
                                            p.gender,
                                            p.birthdate AS dob,
                                            pa.city_village AS address
                                            FROM patient_identifier pid
                                      INNER JOIN person_name pn ON pid.patient_id = pn.person_id AND pn.voided = 0
                                      INNER JOIN person_address pa ON pa.person_id = pn.person_id AND pa.voided = 0
                                      INNER JOIN person p ON pid.patient_id = p.person_id AND p.voided = 0
                                      WHERE pid.voided = 0 AND pid.identifier_type = 3 AND pid.identifier = '#{npid}'
                                      "
		)
    results
  end

  def self.search_by_name(given_name, family_name, gender)
    if gender.match(/F/i)
      gender = 'F'
    else
      gender = 'M'
    end
    given_name_code = given_name.soundex
    family_name_code = family_name.soundex

    results = connection.select_all(
        "SELECT '0' AS patient_number , pid.identifier AS external_patient_number,
                                            CONCAT(COALESCE(pn.given_name, ''), ' ',
                                            COALESCE(pn.family_name, '')) AS name,
                                            p.gender,
                                            p.birthdate AS dob,
                                            pa.city_village AS address
                                            FROM patient_identifier pid
                                      INNER JOIN person_name pn ON pid.patient_id = pn.person_id AND pn.voided = 0
                                      INNER JOIN person_name_code pnc ON pn.person_name_id = pnc.person_name_id
                                      INNER JOIN person_address pa ON pa.person_id = pn.person_id AND pa.voided = 0
                                      INNER JOIN person p ON pid.patient_id = p.person_id AND p.voided = 0
                                      WHERE pid.identifier_type = 3 AND pid.voided = 0 AND p.gender = '#{gender}'
                                        AND pnc.given_name_code = '#{given_name_code}'
                                        AND pnc.family_name_code = '#{family_name_code}'
                                      "
    )
    results
  end

  def self.search_from_dde2_by_npid(npid)
    response = DDE2Service.search_by_identifier(npid)

    results = []
    (response || []).each do |data|
      name = "#{data['names']['given_name']} #{data['names']['middle_name']} #{data['names']['family_name']}"
      address = (data['addresses']['current_village'].blank? || data['addresses']['current_village'] == 'Other') ?
          data['addresses']['current_residence'] : data['addresses']['current_village']
      address = data['addresses']['current_ta'] if (address.blank? || address == 'Other')
      address = data['addresses']['current_district'] if (address.blank? || address == 'Other')

      results << {
          'patient_number' => 0,
          'external_patient_number' => data['npid'],
          'name' => name,
          'gender' => data['gender'],
          'dob' => data['birthdate'],
          'address' => address
      }
    end

    results
  end

  def self.search_from_dde2_by_name(params)
    response = DDE2Service.search_from_dde2(params)
    results = []

    (response || []).each do |data|
      name = "#{data['names']['given_name']} #{data['names']['middle_name']} #{data['names']['family_name']}"
      address = (data['addresses']['current_village'].blank? || data['addresses']['current_village'] == 'Other') ?
          data['addresses']['current_residence'] : data['addresses']['current_village']
      address = data['addresses']['current_ta'] if (address.blank? || address == 'Other')
      address = data['addresses']['current_district'] if (address.blank? || address == 'Other')

      results << {
          'patient_number' => 0,
          'external_patient_number' => data['npid'],
          'name' => name,
          'gender' => data['gender'],
          'dob' => data['birthdate'],
          'address' => address
      }
    end

    results
  end

end
