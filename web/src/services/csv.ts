import Papa from 'papaparse';
import JSZip from 'jszip';
import type { AppData, Aliment, Repas, JourRepas, Entrainement, MesuresCorporelles, ParametresNutritionnels } from '../types';
import { storage } from './storage';

const UTF8_BOM = '\uFEFF';

function downloadBlob(blob: Blob, filename: string): void {
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = filename;
  a.click();
  URL.revokeObjectURL(a.href);
}

function toCSV<T>(rows: T[], columns: (keyof T)[]): string {
  const header = columns.join(',');
  const body = rows.map((row) =>
    columns.map((col) => {
      const v = row[col];
      if (v === undefined || v === null) return '';
      const s = String(v);
      return s.includes(',') || s.includes('"') || s.includes('\n') ? `"${s.replace(/"/g, '""')}"` : s;
    }).join(',')
  ).join('\n');
  return UTF8_BOM + header + '\n' + body;
}

export function exportAlimentsCSV(aliments: Aliment[]): void {
  const cols: (keyof Aliment)[] = ['id', 'nom', 'unite', 'prixUnitaire', 'devise', 'gestionStock', 'quantiteStock', 'seuilAlerte', 'decrementationJournaliere', 'quantiteAchatParDefaut', 'calories', 'proteines', 'lipides', 'glucides', 'poidsUnitaire', 'unitePortionLabel', 'nombreUniteParLot'];
  const csv = toCSV(aliments.map((a) => ({ ...a, gestionStock: a.gestionStock ? 1 : 0 })), cols);
  downloadBlob(new Blob([csv], { type: 'text/csv;charset=utf-8' }), 'aliments.csv');
}

export function exportRepasCSV(repas: Repas[]): void {
  const cols: (keyof Repas)[] = ['id', 'nom', 'createdAt'];
  const csv = toCSV(repas, cols);
  downloadBlob(new Blob([csv], { type: 'text/csv;charset=utf-8' }), 'repas.csv');
}

export function exportRepasAlimentsCSV(repas: Repas[]): void {
  const rows: { repasId: string; alimentId: string; quantite: number }[] = [];
  for (const r of repas) {
    for (const a of r.aliments) {
      rows.push({ repasId: r.id, alimentId: a.alimentId, quantite: a.quantite });
    }
  }
  const csv = toCSV(rows, ['repasId', 'alimentId', 'quantite']);
  downloadBlob(new Blob([csv], { type: 'text/csv;charset=utf-8' }), 'repas_aliments.csv');
}

export function exportJoursRepasCSV(joursRepas: JourRepas[]): void {
  const cols: (keyof JourRepas)[] = ['id', 'date', 'repasId', 'heure', 'minute'];
  const csv = toCSV(joursRepas, cols);
  downloadBlob(new Blob([csv], { type: 'text/csv;charset=utf-8' }), 'jours_repas.csv');
}

interface EntrainementRow {
  id: string;
  date: string;
  type: string;
  dureeMinutes: number;
  distance?: number | '';
  caloriesBrulees?: number | '';
  activite?: string;
  exercices?: string;
}

export function exportEntrainementsCSV(entrainements: Entrainement[]): void {
  const rows: EntrainementRow[] = entrainements.map((e) => {
    const row: EntrainementRow = { id: e.id, date: e.date, type: e.type, dureeMinutes: e.dureeMinutes };
    if (e.type === 'cardio') {
      row.distance = e.distance;
      row.caloriesBrulees = e.caloriesBrulees;
    } else if (e.type === 'divers') {
      row.activite = e.activite;
      row.distance = e.distance ?? '';
      row.caloriesBrulees = e.caloriesBrulees ?? '';
    } else if (e.type === 'musculation') {
      row.exercices = JSON.stringify(e.exercices);
    }
    return row;
  });
  const cols: (keyof EntrainementRow)[] = ['id', 'date', 'type', 'dureeMinutes', 'distance', 'caloriesBrulees', 'activite', 'exercices'];
  const csv = toCSV(rows, cols);
  downloadBlob(new Blob([csv], { type: 'text/csv;charset=utf-8' }), 'entrainements.csv');
}

export function exportMesuresCSV(mesures: MesuresCorporelles[]): void {
  const cols: (keyof MesuresCorporelles)[] = ['id', 'date', 'poids', 'tauxGraisse', 'tauxEau', 'masseMuscle', 'masseOsseuse', 'metabolismeBasal', 'notes'];
  const csv = toCSV(mesures, cols);
  downloadBlob(new Blob([csv], { type: 'text/csv;charset=utf-8' }), 'mesures.csv');
}

export function exportParametresCSV(param: ParametresNutritionnels | null): void {
  if (!param) return;
  const cols: (keyof ParametresNutritionnels)[] = ['id', 'poids', 'taille', 'age', 'sexe', 'niveauActivite', 'objectif', 'objectifProteines', 'objectifLipides', 'objectifGlucides', 'proteinesParKg'];
  const csv = toCSV([param], cols);
  downloadBlob(new Blob([csv], { type: 'text/csv;charset=utf-8' }), 'parametres.csv');
}

export function exportAllCSV(data: AppData): void {
  exportAlimentsCSV(data.aliments);
  exportRepasCSV(data.repas);
  exportRepasAlimentsCSV(data.repas);
  exportJoursRepasCSV(data.joursRepas);
  exportEntrainementsCSV(data.entrainements);
  exportMesuresCSV(data.mesures);
  exportParametresCSV(data.parametres);
}

export async function exportAllZIP(data: AppData): Promise<void> {
  const zip = new JSZip();
  const add = (name: string, content: string) => zip.file(name, UTF8_BOM + content);

  add('aliments.csv', Papa.unparse(data.aliments.map((a) => ({ ...a, gestionStock: a.gestionStock ? 1 : 0 }))));
  add('repas.csv', Papa.unparse(data.repas.map((r) => ({ id: r.id, nom: r.nom, createdAt: r.createdAt }))));
  add('repas_aliments.csv', Papa.unparse(data.repas.flatMap((r) => r.aliments.map((a) => ({ repasId: r.id, alimentId: a.alimentId, quantite: a.quantite })))));
  add('jours_repas.csv', Papa.unparse(data.joursRepas));
  add('entrainements.csv', Papa.unparse(data.entrainements.map((e) => ({ ...e, exercices: e.type === 'musculation' ? JSON.stringify(e.exercices) : undefined }))));
  add('mesures.csv', Papa.unparse(data.mesures));
  if (data.parametres) add('parametres.csv', Papa.unparse([data.parametres]));

  const blob = await zip.generateAsync({ type: 'blob' });
  downloadBlob(blob, 'pigeon_nutrition_export.zip');
}

function parseCSV<T>(text: string): T[] {
  const result = Papa.parse<T>(text, { header: true, skipEmptyLines: true });
  return result.data ?? [];
}

function num(v: unknown): number {
  if (typeof v === 'number' && !Number.isNaN(v)) return v;
  const n = Number(v);
  return Number.isNaN(n) ? 0 : n;
}

function str(v: unknown): string {
  return v != null ? String(v).trim() : '';
}

export interface ImportResult {
  ok: boolean;
  aliments: number;
  repas: number;
  repasAliments: number;
  joursRepas: number;
  entrainements: number;
  mesures: number;
  parametres: number;
  errors: string[];
}

export async function importFromZIP(file: File, merge: boolean): Promise<ImportResult> {
  const zip = await JSZip.loadAsync(file);
  const result: ImportResult = { ok: true, aliments: 0, repas: 0, repasAliments: 0, joursRepas: 0, entrainements: 0, mesures: 0, parametres: 0, errors: [] };
  const data: AppData = merge ? storage.getAll() : { aliments: [], repas: [], joursRepas: [], entrainements: [], mesures: [], parametres: null };

  const read = async (name: string): Promise<string> => {
    const f = zip.file(name);
    if (!f) return '';
    return f.async('string');
  };

  try {
    const alimentsRaw = await read('aliments.csv');
    if (alimentsRaw) {
      const rows = parseCSV<Record<string, unknown>>(alimentsRaw);
      const aliments: Aliment[] = rows.map((row) => ({
        id: str(row.id),
        nom: str(row.nom),
        unite: (str(row.unite) === 'ml' ? 'ml' : 'g') as 'g' | 'ml',
        prixUnitaire: num(row.prixUnitaire),
        devise: str(row.devise) || 'EUR',
        gestionStock: Number(row.gestionStock) === 1,
        quantiteStock: num(row.quantiteStock),
        seuilAlerte: row.seuilAlerte !== '' && row.seuilAlerte != null ? num(row.seuilAlerte) : undefined,
        decrementationJournaliere: row.decrementationJournaliere !== '' && row.decrementationJournaliere != null ? num(row.decrementationJournaliere) : undefined,
        quantiteAchatParDefaut: num(row.quantiteAchatParDefaut) || 1000,
        calories: num(row.calories),
        proteines: num(row.proteines),
        lipides: num(row.lipides),
        glucides: num(row.glucides),
        poidsUnitaire: row.poidsUnitaire !== '' && row.poidsUnitaire != null ? num(row.poidsUnitaire) : undefined,
        unitePortionLabel: str(row.unitePortionLabel) || undefined,
        nombreUniteParLot: row.nombreUniteParLot !== '' && row.nombreUniteParLot != null ? Math.floor(num(row.nombreUniteParLot)) : undefined,
      })).filter((a) => a.id);
      if (!merge) data.aliments = [];
      const existingIds = new Set(data.aliments.map((a) => a.id));
      for (const a of aliments) {
        if (existingIds.has(a.id)) {
          const i = data.aliments.findIndex((x) => x.id === a.id);
          if (i >= 0) data.aliments[i] = a;
        } else {
          data.aliments.push(a);
          existingIds.add(a.id);
        }
      }
      result.aliments = aliments.length;
    }
  } catch (e) {
    result.errors.push(`aliments: ${e instanceof Error ? e.message : String(e)}`);
  }

  try {
    const repasRaw = await read('repas.csv');
    const repasAlimentsRaw = await read('repas_aliments.csv');
    if (repasRaw) {
      const repasRows = parseCSV<Record<string, unknown>>(repasRaw);
      const repasAlimentsRows = repasAlimentsRaw ? parseCSV<Record<string, unknown>>(repasAlimentsRaw) : [];
      const repasMap = new Map<string, Repas>();
      for (const row of repasRows) {
        const id = str(row.id);
        if (!id) continue;
        repasMap.set(id, {
          id,
          nom: str(row.nom),
          aliments: [],
          createdAt: str(row.createdAt) || undefined,
        });
      }
      for (const row of repasAlimentsRows) {
        const repasId = str(row.repasId);
        const repas = repasMap.get(repasId);
        if (repas) repas.aliments.push({ alimentId: str(row.alimentId), quantite: num(row.quantite) });
      }
      const repas = Array.from(repasMap.values());
      if (!merge) data.repas = [];
      const existingRepasIds = new Set(data.repas.map((r) => r.id));
      for (const r of repas) {
        if (existingRepasIds.has(r.id)) {
          const i = data.repas.findIndex((x) => x.id === r.id);
          if (i >= 0) data.repas[i] = r;
        } else {
          data.repas.push(r);
          existingRepasIds.add(r.id);
        }
      }
      result.repas = repas.length;
      result.repasAliments = repasAlimentsRows.length;
    }
  } catch (e) {
    result.errors.push(`repas: ${e instanceof Error ? e.message : String(e)}`);
  }

  try {
    const joursRaw = await read('jours_repas.csv');
    if (joursRaw) {
      const rows = parseCSV<Record<string, unknown>>(joursRaw);
      const joursRepas: JourRepas[] = rows.map((row) => ({
        id: str(row.id),
        date: str(row.date),
        repasId: str(row.repasId),
        heure: Math.floor(num(row.heure)),
        minute: Math.floor(num(row.minute)),
      })).filter((j) => j.id && j.repasId);
      if (!merge) data.joursRepas = [];
      const existingIds = new Set(data.joursRepas.map((j) => j.id));
      for (const j of joursRepas) {
        if (!existingIds.has(j.id)) {
          data.joursRepas.push(j);
          existingIds.add(j.id);
        }
      }
      result.joursRepas = joursRepas.length;
    }
  } catch (e) {
    result.errors.push(`jours_repas: ${e instanceof Error ? e.message : String(e)}`);
  }

  try {
    const entRaw = await read('entrainements.csv');
    if (entRaw) {
      const rows = parseCSV<Record<string, unknown>>(entRaw);
      const entrainements: Entrainement[] = rows.map((row): Entrainement => {
        const type = str(row.type);
        const id = str(row.id);
        const date = str(row.date);
        const dureeMinutes = Math.floor(num(row.dureeMinutes));
        if (type === 'cardio') {
          return { id, date, type: 'cardio', dureeMinutes, distance: num(row.distance), caloriesBrulees: num(row.caloriesBrulees) };
        }
        if (type === 'musculation') {
          let exercices: { nom: string; series: number; repetitions: number; poids: number; muscle: string }[] = [];
          try {
            const ex = row.exercices != null ? JSON.parse(String(row.exercices)) : [];
            exercices = Array.isArray(ex) ? ex : [];
          } catch {}
          return { id, date, type: 'musculation', dureeMinutes, exercices };
        }
        return {
          id,
          date,
          type: 'divers',
          dureeMinutes,
          activite: str(row.activite) || 'Autre',
          distance: row.distance !== '' && row.distance != null ? num(row.distance) : undefined,
          caloriesBrulees: row.caloriesBrulees !== '' && row.caloriesBrulees != null ? num(row.caloriesBrulees) : undefined,
        };
      }).filter((e) => e.id);
      if (!merge) data.entrainements = [];
      const existingIds = new Set(data.entrainements.map((e) => e.id));
      for (const e of entrainements) {
        if (!existingIds.has(e.id)) {
          data.entrainements.push(e);
          existingIds.add(e.id);
        }
      }
      result.entrainements = entrainements.length;
    }
  } catch (e) {
    result.errors.push(`entrainements: ${e instanceof Error ? e.message : String(e)}`);
  }

  try {
    const mesuresRaw = await read('mesures.csv');
    if (mesuresRaw) {
      const rows = parseCSV<Record<string, unknown>>(mesuresRaw);
      const mesures: MesuresCorporelles[] = rows.map((row) => ({
        id: str(row.id),
        date: str(row.date),
        poids: num(row.poids),
        tauxGraisse: row.tauxGraisse !== '' && row.tauxGraisse != null ? num(row.tauxGraisse) : undefined,
        tauxEau: row.tauxEau !== '' && row.tauxEau != null ? num(row.tauxEau) : undefined,
        masseMuscle: row.masseMuscle !== '' && row.masseMuscle != null ? num(row.masseMuscle) : undefined,
        masseOsseuse: row.masseOsseuse !== '' && row.masseOsseuse != null ? num(row.masseOsseuse) : undefined,
        metabolismeBasal: row.metabolismeBasal !== '' && row.metabolismeBasal != null ? num(row.metabolismeBasal) : undefined,
        notes: str(row.notes) || undefined,
      })).filter((m) => m.id);
      if (!merge) data.mesures = [];
      const existingIds = new Set(data.mesures.map((m) => m.id));
      for (const m of mesures) {
        if (!existingIds.has(m.id)) {
          data.mesures.push(m);
          existingIds.add(m.id);
        }
      }
      result.mesures = mesures.length;
    }
  } catch (e) {
    result.errors.push(`mesures: ${e instanceof Error ? e.message : String(e)}`);
  }

  try {
    const paramRaw = await read('parametres.csv');
    if (paramRaw) {
      const rows = parseCSV<Record<string, unknown>>(paramRaw);
      const row = rows[0];
      if (row && str(row.id)) {
        data.parametres = {
          id: str(row.id),
          poids: num(row.poids),
          taille: num(row.taille),
          age: Math.floor(num(row.age)),
          sexe: str(row.sexe) === 'femme' ? 'femme' : 'homme',
          niveauActivite: (str(row.niveauActivite) || 'sedentaire') as ParametresNutritionnels['niveauActivite'],
          objectif: (str(row.objectif) || 'maintien') as ParametresNutritionnels['objectif'],
          objectifProteines: num(row.objectifProteines) || 30,
          objectifLipides: num(row.objectifLipides) || 25,
          objectifGlucides: num(row.objectifGlucides) || 45,
          proteinesParKg: num(row.proteinesParKg) || 1.6,
        };
        result.parametres = 1;
      }
    }
  } catch (e) {
    result.errors.push(`parametres: ${e instanceof Error ? e.message : String(e)}`);
  }

  storage.setAll(data);
  result.ok = result.errors.length === 0;
  return result;
}

// Import from single CSV (e.g. aliments.csv only)
export function importAlimentsFromCSV(text: string, merge: boolean): ImportResult {
  const result: ImportResult = { ok: true, aliments: 0, repas: 0, repasAliments: 0, joursRepas: 0, entrainements: 0, mesures: 0, parametres: 0, errors: [] };
  const data = storage.getAll();
  const rows = parseCSV<Record<string, unknown>>(text);
  const aliments: Aliment[] = rows.map((row) => ({
    id: str(row.id),
    nom: str(row.nom),
    unite: (str(row.unite) === 'ml' ? 'ml' : 'g') as 'g' | 'ml',
    prixUnitaire: num(row.prixUnitaire),
    devise: str(row.devise) || 'EUR',
    gestionStock: Number(row.gestionStock) === 1,
    quantiteStock: num(row.quantiteStock),
    seuilAlerte: row.seuilAlerte !== '' && row.seuilAlerte != null ? num(row.seuilAlerte) : undefined,
    decrementationJournaliere: row.decrementationJournaliere !== '' && row.decrementationJournaliere != null ? num(row.decrementationJournaliere) : undefined,
    quantiteAchatParDefaut: num(row.quantiteAchatParDefaut) || 1000,
    calories: num(row.calories),
    proteines: num(row.proteines),
    lipides: num(row.lipides),
    glucides: num(row.glucides),
    poidsUnitaire: row.poidsUnitaire !== '' && row.poidsUnitaire != null ? num(row.poidsUnitaire) : undefined,
    unitePortionLabel: str(row.unitePortionLabel) || undefined,
    nombreUniteParLot: row.nombreUniteParLot !== '' && row.nombreUniteParLot != null ? Math.floor(num(row.nombreUniteParLot)) : undefined,
  })).filter((a) => a.id);
  if (!merge) data.aliments = [];
  const existingIds = new Set(data.aliments.map((a) => a.id));
  for (const a of aliments) {
    if (existingIds.has(a.id)) {
      const i = data.aliments.findIndex((x) => x.id === a.id);
      if (i >= 0) data.aliments[i] = a;
    } else {
      data.aliments.push(a);
      existingIds.add(a.id);
    }
  }
  result.aliments = aliments.length;
  storage.setAll(data);
  return result;
}
