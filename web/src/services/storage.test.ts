import { describe, it, expect, beforeEach, vi } from 'vitest';
import { storage } from './storage';
import type { Aliment, Repas, JourRepas, Entrainement, MesuresCorporelles, ParametresNutritionnels, AppData } from '../types';

const mockStorage: Record<string, string> = {};
const localStorageMock = {
  getItem: vi.fn((key: string) => mockStorage[key] ?? null),
  setItem: vi.fn((key: string, value: string) => {
    mockStorage[key] = value;
  }),
  removeItem: vi.fn((key: string) => {
    delete mockStorage[key];
  }),
  clear: vi.fn(() => {
    Object.keys(mockStorage).forEach((k) => delete mockStorage[k]);
  }),
  length: 0,
  key: vi.fn(),
};

describe('storage', () => {
  beforeEach(() => {
    vi.stubGlobal('localStorage', localStorageMock);
    Object.keys(mockStorage).forEach((k) => delete mockStorage[k]);
  });

  it('getAliments returns [] when empty', () => {
    expect(storage.getAliments()).toEqual([]);
  });

  it('setAliments then getAliments roundtrip', () => {
    const aliments: Aliment[] = [
      {
        id: 'a1',
        nom: 'Test',
        unite: 'g',
        prixUnitaire: 0,
        devise: 'EUR',
        gestionStock: false,
        quantiteStock: 0,
        quantiteAchatParDefaut: 1000,
        calories: 100,
        proteines: 10,
        lipides: 5,
        glucides: 15,
      },
    ];
    storage.setAliments(aliments);
    expect(storage.getAliments()).toEqual(aliments);
  });

  it('getRepas / setRepas roundtrip', () => {
    const repas: Repas[] = [{ id: 'r1', nom: 'R', aliments: [] }];
    storage.setRepas(repas);
    expect(storage.getRepas()).toEqual(repas);
  });

  it('getJoursRepas / setJoursRepas roundtrip', () => {
    const jr: JourRepas[] = [{ id: 'j1', date: '2025-02-07', repasId: 'r1', heure: 12, minute: 0 }];
    storage.setJoursRepas(jr);
    expect(storage.getJoursRepas()).toEqual(jr);
  });

  it('getEntrainements / setEntrainements roundtrip', () => {
    const ent: Entrainement[] = [
      { id: 'e1', date: '2025-02-07', type: 'cardio', dureeMinutes: 30, distance: 5, caloriesBrulees: 200 },
    ];
    storage.setEntrainements(ent);
    expect(storage.getEntrainements()).toEqual(ent);
  });

  it('getMesures / setMesures roundtrip', () => {
    const mes: MesuresCorporelles[] = [{ id: 'm1', date: '2025-02-07', poids: 70 }];
    storage.setMesures(mes);
    expect(storage.getMesures()).toEqual(mes);
  });

  it('getParametres returns null when empty', () => {
    expect(storage.getParametres()).toBeNull();
  });

  it('setParametres then getParametres roundtrip', () => {
    const param: ParametresNutritionnels = {
      id: 'p1',
      poids: 70,
      taille: 175,
      age: 30,
      sexe: 'homme',
      niveauActivite: 'modere',
      objectif: 'maintien',
      objectifProteines: 30,
      objectifLipides: 25,
      objectifGlucides: 45,
      proteinesParKg: 1.6,
    };
    storage.setParametres(param);
    expect(storage.getParametres()).toEqual(param);
  });

  it('getAll returns full AppData', () => {
    const data: AppData = {
      aliments: [],
      repas: [],
      joursRepas: [],
      entrainements: [],
      mesures: [],
      parametres: null,
    };
    storage.setAll(data);
    expect(storage.getAll()).toEqual(data);
  });

  it('setAll then getAll roundtrip', () => {
    const data: AppData = {
      aliments: [{ id: 'a1', nom: 'A', unite: 'g', prixUnitaire: 0, devise: 'EUR', gestionStock: false, quantiteStock: 0, quantiteAchatParDefaut: 1000, calories: 0, proteines: 0, lipides: 0, glucides: 0 }],
      repas: [{ id: 'r1', nom: 'R', aliments: [] }],
      joursRepas: [],
      entrainements: [],
      mesures: [],
      parametres: null,
    };
    storage.setAll(data);
    expect(storage.getAll()).toEqual(data);
  });

  it('returns default when localStorage has invalid JSON', () => {
    localStorageMock.setItem('pigeon_aliments', 'not json');
    expect(storage.getAliments()).toEqual([]);
  });
});
