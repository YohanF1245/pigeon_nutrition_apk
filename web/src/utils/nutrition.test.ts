import { describe, it, expect } from 'vitest';
import { nutrimentsRepas, macrosPourDate, nutritionHistory } from './nutrition';
import type { Aliment, Repas, JourRepas } from '../types';

const aliments: Aliment[] = [
  {
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
  },
  {
    id: 'a2',
    nom: 'Poulet',
    unite: 'g',
    prixUnitaire: 0,
    devise: 'EUR',
    gestionStock: false,
    quantiteStock: 0,
    quantiteAchatParDefaut: 1000,
    calories: 239,
    proteines: 27,
    lipides: 14,
    glucides: 0,
  },
];

describe('nutrimentsRepas', () => {
  it('returns zeros for empty repas', () => {
    const repas: Repas = { id: 'r1', nom: 'Vide', aliments: [] };
    expect(nutrimentsRepas(repas, aliments)).toEqual({
      calories: 0,
      proteines: 0,
      lipides: 0,
      glucides: 0,
    });
  });

  it('computes macros from aliments with ratio quantite/100', () => {
    const repas: Repas = {
      id: 'r1',
      nom: 'Repas',
      aliments: [
        { alimentId: 'a1', quantite: 200 },
        { alimentId: 'a2', quantite: 100 },
      ],
    };
    const n = nutrimentsRepas(repas, aliments);
    expect(n.calories).toBeCloseTo(130 * 2 + 239 * 1);
    expect(n.proteines).toBeCloseTo(2.7 * 2 + 27 * 1);
    expect(n.lipides).toBeCloseTo(0.3 * 2 + 14 * 1);
    expect(n.glucides).toBeCloseTo(28 * 2 + 0);
  });

  it('skips unknown aliment ids', () => {
    const repas: Repas = {
      id: 'r1',
      nom: 'Repas',
      aliments: [{ alimentId: 'inconnu', quantite: 100 }],
    };
    expect(nutrimentsRepas(repas, aliments)).toEqual({
      calories: 0,
      proteines: 0,
      lipides: 0,
      glucides: 0,
    });
  });
});

describe('macrosPourDate', () => {
  it('returns zeros when no jour for date', () => {
    const joursRepas: JourRepas[] = [];
    const repasList: Repas[] = [];
    expect(macrosPourDate('2025-02-07', joursRepas, repasList, aliments)).toEqual({
      calories: 0,
      proteines: 0,
      lipides: 0,
      glucides: 0,
    });
  });

  it('aggregates macros for all repas of the date', () => {
    const repas1: Repas = {
      id: 'r1',
      nom: 'R1',
      aliments: [{ alimentId: 'a1', quantite: 100 }],
    };
    const repas2: Repas = {
      id: 'r2',
      nom: 'R2',
      aliments: [{ alimentId: 'a2', quantite: 100 }],
    };
    const joursRepas: JourRepas[] = [
      { id: 'j1', date: '2025-02-07', repasId: 'r1', heure: 8, minute: 0 },
      { id: 'j2', date: '2025-02-07', repasId: 'r2', heure: 12, minute: 30 },
    ];
    const n = macrosPourDate('2025-02-07', joursRepas, [repas1, repas2], aliments);
    expect(n.calories).toBeCloseTo(130 + 239);
    expect(n.proteines).toBeCloseTo(2.7 + 27);
  });

  it('ignores jours with unknown repasId', () => {
    const joursRepas: JourRepas[] = [
      { id: 'j1', date: '2025-02-07', repasId: 'r-ghost', heure: 8, minute: 0 },
    ];
    const n = macrosPourDate('2025-02-07', joursRepas, [], aliments);
    expect(n).toEqual({ calories: 0, proteines: 0, lipides: 0, glucides: 0 });
  });
});

describe('nutritionHistory', () => {
  it('returns one day when days=1', () => {
    const hist = nutritionHistory(1, [], [], []);
    expect(hist).toHaveLength(1);
    expect(hist[0].calories).toBe(0);
    expect(hist[0].date).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });

  it('returns N consecutive days with correct structure', () => {
    const hist = nutritionHistory(3, [], [], []);
    expect(hist).toHaveLength(3);
    const [d0, d1, d2] = hist.map((h) => h.date);
    const day0 = new Date(d0).getTime();
    const day1 = new Date(d1).getTime();
    const day2 = new Date(d2).getTime();
    expect(day1 - day0).toBe(24 * 60 * 60 * 1000);
    expect(day2 - day1).toBe(24 * 60 * 60 * 1000);
  });
});
