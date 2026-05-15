class AddLiverDiseases < ActiveRecord::Migration[8.1]
  def change
    liver_diseases = [
      { name: "hepatitis_b", description: "Hepatitis B is a liver infection caused by the hepatitis B virus (HBV)." },
      { name: "hepatitis_c", description: "Hepatitis C is a liver infection caused by the hepatitis C virus (HCV)." },
      { name: "cirrhosis", description: "Cirrhosis is a late stage of progressive liver fibrosis characterized by distortion of the liver architecture." },
      { name: "nafld", description: "Non-alcoholic fatty liver disease (NAFLD) is a condition where fat builds up in the liver." },
      { name: "nash", description: "Non-alcoholic steatohepatitis (NASH) is an advanced form of NAFLD characterized by liver inflammation." },
      { name: "liver_cancer", description: "Liver cancer includes hepatocellular carcinoma and cholangiocarcinoma." }
    ]

    liver_diseases.each do |disease|
      unless PredefinedDisease.exists?(name: disease[:name])
        PredefinedDisease.create!(name: disease[:name], description: disease[:description])
      end
    end
  end
end
