Rails.logger.debug "Seeding predefined diseases ..."

PredefinedDisease.create(
  [
    {
      name: "atopic dermatitis",
      description: "A skin condition characterized by rashes and itching.",
      icd10_code: "L20"
    },
    {
      name: "multiple sclerosis",
      description: "A neurological disease causing damage to the myelin sheath of nerves.",
      icd10_code: "G35"
    },
    {
      name: "overweight",
      description: "A condition related to an excessive amount of body fat.",
      icd10_code: "E66"
    },
    {
      name: "diabetes",
      description: "A metabolic disease affecting the blood sugar level.",
      icd10_code: "E14"
    },
    {
      name: "heart failure",
      description: "A condition in which the heart cannot pump blood effectively enough.",
      icd10_code: "I50"
    },
    {
      name: "osteoporosis",
      description: "A bone disease characterized by a loss of bone mass.",
      icd10_code: "M80"
    },
    {
      name: "hypertension",
      description: "High blood pressure, increasing the risk of heart diseases.",
      icd10_code: "I10"
    },
    {
      name: "hypothyroidism",
      description: "A condition in which the thyroid gland doesn't produce enough hormones.",
      icd10_code: "E03"
    },
    {
      name: "asthma",
      description: "A respiratory disease causing bronchial spasms.",
      icd10_code: "J45"
    },
    {
      name: "celiac disease",
      description: "An intestinal disease that hinders gluten digestion.",
      icd10_code: "K90"
    },
    {
      name: "psoriasis",
      description: "A skin condition characterized by patches and scales.",
      icd10_code: "L40"
    },
    {
      name: "crohns disease",
      description: "A chronic inflammatory bowel disease.",
      icd10_code: "K50"
    },
    {
      name: "parkinsons disease",
      description: "A neurodegenerative disease affecting movement control.",
      icd10_code: "G20"
    },
    {
      name: "endometriosis",
      description: "A gynecological condition where uterine tissue grows outside the uterus.",
      icd10_code: "N80"
    }
  ]
)

Rails.logger.debug "Seeding predefined diseases done."
