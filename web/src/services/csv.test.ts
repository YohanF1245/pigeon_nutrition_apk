import { describe, it, expect, vi, beforeEach } from 'vitest';
import JSZip from 'jszip';
import {
  exportAlimentsCSV,
  exportRepasCSV,
  exportRepasAlimentsCSV,
  exportJoursRepasCSV,
  exportEntrainementsCSV,
  exportMesuresCSV,
  exportParametresCSV,
  exportAllCSV,
  exportAllZIP,
  importFromZIP,
  importAlimentsFromCSV,
} from './csv';
import type { Aliment, Repas, JourRepas, Entrainement, MesuresCorporelles, ParametresNutritionnels, AppData } from '../types';
import { storage } from './storage';

beforeEach(() => {
  const mockStorage: Record<string, string> = {};
  vi.stubGlobal('localStorage', {
    getItem: (key: string) => mockStorage[key] ?? null,
    setItem: (key: string, value: string) => { mockStorage[key] = value; },
    removeItem: (key: string) => { delete mockStorage[key]; },
    clear: () => { Object.keys(mockStorage).forEach((k) => delete mockStorage[k]); },
    length: 0,
    key: () => null,
  });
});

describe('exportAlimentsCSV', () => {
  it('does not throw', () => {
    const aliments: Aliment[] = [{
      id: 'a1',
      nom: 'Riz',
      unite: 'g',
      prixUnitaire: 0,
      devise: 'EUR',
      gestionStock: false,
      quantiteStock: 0,
      quantiteAchatParDefaut: 1000,
      calories: 130,
      proteines: 2.7,
      lipides: 0.3,
      glucides: 28,
    }];
    exportAlimentsCSV(aliments);
  });
});

describe('exportRepasCSV', () => {
  it('exports repas list', () => {
    const repas: Repas[] = [{ id: 'r1', nom: 'Petit-déj', aliments: [] }];
    exportRepasCSV(repas);
  });
});

describe('exportRepasAlimentsCSV', () => {
  it('exports repas-aliments rows', () => {
    const repas: Repas[] = [{
      id: 'r1',
      nom: 'R',
      aliments: [{ alimentId: 'a1', quantite: 100 }],
    }];
    exportRepasAlimentsCSV(repas);
  });
});

describe('exportJoursRepasCSV', () => {
  it('exports jours_repas', () => {
    const jr: JourRepas[] = [{ id: 'j1', date: '2025-02-07', repasId: 'r1', heure: 8, minute: 0 }];
    exportJoursRepasCSV(jr);
  });
});

describe('exportEntrainementsCSV', () => {
  it('exports cardio', () => {
    const ent: Entrainement[] = [{
      id: 'e1',
      date: '2025-02-07',
      type: 'cardio',
      dureeMinutes: 30,
      distance: 5,
      caloriesBrulees: 200,
    }];
    exportEntrainementsCSV(ent);
  });
  it('exports musculation', () => {
    const ent: Entrainement[] = [{
      id: 'e1',
      date: '2025-02-07',
      type: 'musculation',
      dureeMinutes: 45,
      exercices: [{ nom: 'Squat', series: 3, repetitions: 10, poids: 60, muscle: 'jambes' }],
    }];
    exportEntrainementsCSV(ent);
  });
  it('exports divers', () => {
    const ent: Entrainement[] = [{
      id: 'e1',
      date: '2025-02-07',
      type: 'divers',
      dureeMinutes: 20,
      activite: 'Yoga',
    }];
    exportEntrainementsCSV(ent);
  });
});

describe('exportMesuresCSV', () => {
  it('exports mesures', () => {
    const mes: MesuresCorporelles[] = [{ id: 'm1', date: '2025-02-07', poids: 70 }];
    exportMesuresCSV(mes);
  });
});

describe('exportParametresCSV', () => {
  it('does nothing when param is null', () => {
    exportParametresCSV(null);
  });
  it('exports when param set', () => {
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
    exportParametresCSV(param);
  });
});

describe('exportAllCSV', () => {
  it('calls all entity exports', () => {
    const data: AppData = {
      aliments: [],
      repas: [],
      joursRepas: [],
      entrainements: [],
      mesures: [],
      parametres: null,
    };
    exportAllCSV(data);
  });
});

describe('exportAllZIP', () => {
  it('produces ZIP blob', async () => {
    const data: AppData = {
      aliments: [],
      repas: [],
      joursRepas: [],
      entrainements: [],
      mesures: [],
      parametres: null,
    };
    await exportAllZIP(data);
  });
});

describe('importFromZIP', () => {
  it('rejects when file is not valid ZIP', async () => {
    const file = new File(['not a zip'], 'x.zip');
    await expect(importFromZIP(file, false)).rejects.toThrow();
  });

  it('imports aliments from ZIP', async () => {
    const zip = new JSZip();
    zip.file('aliments.csv', '\uFEFFid,nom,unite,prixUnitaire,devise,gestionStock,quantiteStock,calories,proteines,lipides,glucides,quantiteAchatParDefaut\nid1,Riz,g,0,EUR,0,0,130,2.7,0.3,28,1000');
    const blob = await zip.generateAsync({ type: 'blob' });
    const file = new File([blob], 'export.zip');
    const r = await importFromZIP(file, false);
    expect(r.aliments).toBe(1);
    expect(storage.getAliments()).toHaveLength(1);
    expect(storage.getAliments()[0].nom).toBe('Riz');
  });

  it('merge mode merges with existing', async () => {
    storage.setAll({
      aliments: [{
        id: 'a0',
        nom: 'Existing',
        unite: 'g',
        prixUnitaire: 0,
        devise: 'EUR',
        gestionStock: false,
        quantiteStock: 0,
        quantiteAchatParDefaut: 1000,
        calories: 0,
        proteines: 0,
        lipides: 0,
        glucides: 0,
      }],
      repas: [],
      joursRepas: [],
      entrainements: [],
      mesures: [],
      parametres: null,
    });
    const zip = new JSZip();
    zip.file('aliments.csv', '\uFEFFid,nom,unite,prixUnitaire,devise,gestionStock,quantiteStock,calories,proteines,lipides,glucides,quantiteAchatParDefaut\nid1,Riz,g,0,EUR,0,0,130,2.7,0.3,28,1000');
    const blob = await zip.generateAsync({ type: 'blob' });
    const r = await importFromZIP(new File([blob], 'x.zip'), true);
    expect(r.aliments).toBe(1);
    const al = storage.getAliments();
    expect(al.length).toBe(2);
    expect(al.some((a) => a.id === 'a0')).toBe(true);
    expect(al.some((a) => a.id === 'id1')).toBe(true);
  });
});

describe('importAlimentsFromCSV', () => {
  it('imports from CSV text', () => {
    const csv = 'id,nom,unite,prixUnitaire,devise,gestionStock,quantiteStock,calories,proteines,lipides,glucides,quantiteAchatParDefaut\nid1,Poulet,g,0,EUR,0,0,239,27,14,0,1000';
    const r = importAlimentsFromCSV(csv, false);
    expect(r.ok).toBe(true);
    expect(r.aliments).toBe(1);
    expect(storage.getAliments()[0].nom).toBe('Poulet');
  });
  it('merge false replaces aliments', () => {
    storage.setAliments([{
      id: 'old',
      nom: 'Old',
      unite: 'g',
      prixUnitaire: 0,
      devise: 'EUR',
      gestionStock: false,
      quantiteStock: 0,
      quantiteAchatParDefaut: 1000,
      calories: 0,
      proteines: 0,
      lipides: 0,
      glucides: 0,
    }]);
    const csv = 'id,nom,unite,prixUnitaire,devise,gestionStock,quantiteStock,calories,proteines,lipides,glucides,quantiteAchatParDefaut\nid1,New,g,0,EUR,0,0,100,10,5,10,1000';
    importAlimentsFromCSV(csv, false);
    expect(storage.getAliments()).toHaveLength(1);
    expect(storage.getAliments()[0].id).toBe('id1');
  });
});
