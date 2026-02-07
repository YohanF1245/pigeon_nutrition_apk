import type { AppData, Aliment, Repas, JourRepas, Entrainement, MesuresCorporelles, ParametresNutritionnels } from '../types';

const KEYS = {
  aliments: 'pigeon_aliments',
  repas: 'pigeon_repas',
  joursRepas: 'pigeon_jours_repas',
  entrainements: 'pigeon_entrainements',
  mesures: 'pigeon_mesures',
  parametres: 'pigeon_parametres',
} as const;

function get<T>(key: string, defaultValue: T): T {
  try {
    const raw = localStorage.getItem(key);
    if (raw == null) return defaultValue;
    return JSON.parse(raw) as T;
  } catch {
    return defaultValue;
  }
}

function set(key: string, value: unknown): void {
  localStorage.setItem(key, JSON.stringify(value));
}

export const storage = {
  getAliments(): Aliment[] {
    return get(KEYS.aliments, []);
  },
  setAliments(aliments: Aliment[]): void {
    set(KEYS.aliments, aliments);
  },

  getRepas(): Repas[] {
    return get(KEYS.repas, []);
  },
  setRepas(repas: Repas[]): void {
    set(KEYS.repas, repas);
  },

  getJoursRepas(): JourRepas[] {
    return get(KEYS.joursRepas, []);
  },
  setJoursRepas(joursRepas: JourRepas[]): void {
    set(KEYS.joursRepas, joursRepas);
  },

  getEntrainements(): Entrainement[] {
    return get(KEYS.entrainements, []);
  },
  setEntrainements(entrainements: Entrainement[]): void {
    set(KEYS.entrainements, entrainements);
  },

  getMesures(): MesuresCorporelles[] {
    return get(KEYS.mesures, []);
  },
  setMesures(mesures: MesuresCorporelles[]): void {
    set(KEYS.mesures, mesures);
  },

  getParametres(): ParametresNutritionnels | null {
    return get(KEYS.parametres, null);
  },
  setParametres(param: ParametresNutritionnels | null): void {
    set(KEYS.parametres, param);
  },

  getAll(): AppData {
    return {
      aliments: this.getAliments(),
      repas: this.getRepas(),
      joursRepas: this.getJoursRepas(),
      entrainements: this.getEntrainements(),
      mesures: this.getMesures(),
      parametres: this.getParametres(),
    };
  },

  setAll(data: AppData): void {
    this.setAliments(data.aliments);
    this.setRepas(data.repas);
    this.setJoursRepas(data.joursRepas);
    this.setEntrainements(data.entrainements);
    this.setMesures(data.mesures);
    this.setParametres(data.parametres);
  },
};
