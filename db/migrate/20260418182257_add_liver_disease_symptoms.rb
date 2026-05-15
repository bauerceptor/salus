class AddLiverDiseaseSymptoms < ActiveRecord::Migration[8.1]
  def change
    liver_symptoms = {
      "hepatitis_b" => [
        "HBV - Fatigue",
        "HBV - Jaundice",
        "HBV - Abdominal pain",
        "HBV - Dark urine",
        "HBV - Nausea",
        "HBV - Loss of appetite",
        "HBV - Joint pain",
        "HBV - Yellow skin"
      ],
      "hepatitis_c" => [
        "HCV - Fatigue",
        "HCV - Jaundice",
        "HCV - Abdominal pain",
        "HCV - Dark urine",
        "HCV - Nausea",
        "HCV - Joint pain",
        "HCV - Muscle aches",
        "HCV - Itchiness"
      ],
      "cirrhosis" => [
        "Cirrhosis - Fatigue",
        "Cirrhosis - Jaundice",
        "Cirrhosis - Ascites",
        "Cirrhosis - Edema",
        "Cirrhosis - Easy bruising",
        "Cirrhosis - Confusion",
        "Cirrhosis - Spider angiomas",
        "Cirrhosis - Red palms",
        "Cirrhosis - Weight loss"
      ],
      "nafld" => [
        "NAFLD - Fatigue",
        "NAFLD - Abdominal discomfort",
        "NAFLD - Enlarged liver",
        "NAFLD - Upper abdominal pain"
      ],
      "nash" => [
        "NASH - Fatigue",
        "NASH - Weakness",
        "NASH - Abdominal discomfort",
        "NASH - Upper abdominal pain",
        "NASH - Jaundice"
      ],
      "liver_cancer" => [
        "Liver Cancer - Weight loss",
        "Liver Cancer - Loss of appetite",
        "Liver Cancer - Early satiety",
        "Liver Cancer - Pain",
        "Liver Cancer - Abdominal swelling",
        "Liver Cancer - Jaundice",
        "Liver Cancer - Dark urine",
        "Liver Cancer - Pale stools"
      ]
    }

    liver_symptoms.each do |disease_name, symptom_names|
      disease = PredefinedDisease.find_by(name: disease_name)
      next unless disease

      symptom_names.each do |symptom_name|
        existing = PredefinedSymptom.find_by(name: symptom_name, predefined_disease_id: disease.id)
        next if existing

        PredefinedSymptom.create!(
          name: symptom_name,
          predefined_disease_id: disease.id,
          description: "Symptom associated with #{disease_name}"
        )
      end
    end
  end
end
