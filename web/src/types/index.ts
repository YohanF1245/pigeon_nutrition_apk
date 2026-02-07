export type UniteBase = 'g' | 'ml';

export interface Aliment {
  id: string;
  nom: string;
  unite: UniteBase;
  prixUnitaire: number;
  devise: string;
  gestionStock: boolean;
  quantiteStock: number;
  seuilAlerte?: number;
  decrementationJournaliere?: number;
  quantiteAchatParDefaut: number;
  calories: number;
  proteines: number;
  lipides: number;
  glucides: number;
  poidsUnitaire?: number;
  unitePortionLabel?: string;
  nombreUniteParLot?: number;
}

export interface RepasAliment {
  alimentId: string;
  quantite: number;
}

export interface Repas {
  id: string;
  nom: string;
  aliments: RepasAliment[];
  nutrimentsCaches?: Record<string, number>;
  createdAt?: string;
}

export interface JourRepas {
  id: string;
  date: string;
  repasId: string;
  heure: number;
  minute: number;
}

export interface ExerciceMusculation {
  nom: string;
  series: number;
  repetitions: number;
  poids: number;
  muscle: string;
}

export type Entrainement =
  | {
      id: string;
      date: string;
      type: 'cardio';
      dureeMinutes: number;
      distance: number;
      caloriesBrulees: number;
    }
  | {
      id: string;
      date: string;
      type: 'musculation';
      dureeMinutes: number;
      exercices: ExerciceMusculation[];
    }
  | {
      id: string;
      date: string;
      type: 'divers';
      dureeMinutes: number;
      activite: string;
      distance?: number;
      caloriesBrulees?: number;
    };

export interface MesuresCorporelles {
  id: string;
  date: string;
  poids: number;
  tauxGraisse?: number;
  tauxEau?: number;
  masseMuscle?: number;
  masseOsseuse?: number;
  metabolismeBasal?: number;
  notes?: string;
}

export interface ParametresNutritionnels {
  id: string;
  poids: number;
  taille: number;
  age: number;
  sexe: 'homme' | 'femme';
  niveauActivite: 'sedentaire' | 'leger' | 'modere' | 'intense' | 'tres_intense';
  objectif: 'perte' | 'maintien' | 'prise';
  objectifProteines: number;
  objectifLipides: number;
  objectifGlucides: number;
  proteinesParKg: number;
  tmb?: number;
  caloriesQuotidiennes?: number;
  objectifProteinesGrammes?: number;
  objectifLipidesGrammes?: number;
  objectifGlucidesGrammes?: number;
}

export interface AppData {
  aliments: Aliment[];
  repas: Repas[];
  joursRepas: JourRepas[];
  entrainements: Entrainement[];
  mesures: MesuresCorporelles[];
  parametres: ParametresNutritionnels | null;
}
