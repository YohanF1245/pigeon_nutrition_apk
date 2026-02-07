import type { Aliment, Repas, JourRepas } from '../types';

export function nutrimentsRepas(repas: Repas, aliments: Aliment[]): { calories: number; proteines: number; lipides: number; glucides: number } {
  let calories = 0, proteines = 0, lipides = 0, glucides = 0;
  for (const ra of repas.aliments) {
    const a = aliments.find((x) => x.id === ra.alimentId);
    if (!a) continue;
    const ratio = ra.quantite / 100;
    calories += a.calories * ratio;
    proteines += a.proteines * ratio;
    lipides += a.lipides * ratio;
    glucides += a.glucides * ratio;
  }
  return { calories, proteines, lipides, glucides };
}

export function macrosPourDate(
  dateStr: string,
  joursRepas: JourRepas[],
  repasList: Repas[],
  aliments: Aliment[]
): { calories: number; proteines: number; lipides: number; glucides: number } {
  const jrs = joursRepas.filter((j) => j.date === dateStr);
  let calories = 0, proteines = 0, lipides = 0, glucides = 0;
  for (const jr of jrs) {
    const r = repasList.find((x) => x.id === jr.repasId);
    if (!r) continue;
    const n = nutrimentsRepas(r, aliments);
    calories += n.calories;
    proteines += n.proteines;
    lipides += n.lipides;
    glucides += n.glucides;
  }
  return { calories, proteines, lipides, glucides };
}

export function nutritionHistory(
  days: number,
  joursRepas: JourRepas[],
  repasList: Repas[],
  aliments: Aliment[]
): { date: string; calories: number; proteines: number; lipides: number; glucides: number }[] {
  const end = new Date();
  const start = new Date(end);
  start.setDate(start.getDate() - (days - 1));
  start.setHours(0, 0, 0, 0);
  end.setHours(0, 0, 0, 0);
  const result: { date: string; calories: number; proteines: number; lipides: number; glucides: number }[] = [];
  const cur = new Date(start);
  while (cur <= end) {
    const dateStr = cur.toISOString().slice(0, 10);
    const macros = macrosPourDate(dateStr, joursRepas, repasList, aliments);
    result.push({ ...macros, date: dateStr });
    cur.setDate(cur.getDate() + 1);
  }
  return result;
}
