import { useApp } from '../context/AppContext';
import { exportParametresCSV } from '../services/csv';
import { useCallback, useState } from 'react';
import type { ParametresNutritionnels } from '../types';

function computeBesoins(p: ParametresNutritionnels): ParametresNutritionnels {
  const tmb = p.sexe === 'homme'
    ? 10 * p.poids + 6.25 * p.taille - 5 * p.age + 5
    : 10 * p.poids + 6.25 * p.taille - 5 * p.age - 161;
  const facteur = { sedentaire: 1.2, leger: 1.375, modere: 1.55, intense: 1.725, tres_intense: 1.9 }[p.niveauActivite] ?? 1.2;
  let calories = tmb * facteur;
  if (p.objectif === 'perte') calories *= 0.8;
  else if (p.objectif === 'prise') calories *= 1.1;
  const proteinesGrammes = p.poids * (p.proteinesParKg || 1.6);
  const lipidesGrammes = (calories * (p.objectifLipides / 100)) / 9;
  const glucidesGrammes = (calories - proteinesGrammes * 4 - lipidesGrammes * 9) / 4;
  return {
    ...p,
    tmb,
    caloriesQuotidiennes: calories,
    objectifProteinesGrammes: proteinesGrammes,
    objectifLipidesGrammes: lipidesGrammes,
    objectifGlucidesGrammes: glucidesGrammes,
  };
}

export function Parametres() {
  const { parametres, setParametres } = useApp();
  const [form, setForm] = useState(() => ({
    poids: parametres?.poids ?? 70,
    taille: parametres?.taille ?? 175,
    age: parametres?.age ?? 30,
    sexe: (parametres?.sexe ?? 'homme') as 'homme' | 'femme',
    niveauActivite: (parametres?.niveauActivite ?? 'modere') as ParametresNutritionnels['niveauActivite'],
    objectif: (parametres?.objectif ?? 'maintien') as ParametresNutritionnels['objectif'],
    objectifProteines: parametres?.objectifProteines ?? 30,
    objectifLipides: parametres?.objectifLipides ?? 25,
    objectifGlucides: parametres?.objectifGlucides ?? 45,
    proteinesParKg: parametres?.proteinesParKg ?? 1.6,
  }));

  const handleExport = useCallback(() => {
    exportParametresCSV(parametres);
  }, [parametres]);

  const handleSave = useCallback(() => {
    const id = parametres?.id ?? crypto.randomUUID();
    const next = computeBesoins({
      id,
      ...form,
    });
    setParametres(next);
  }, [form, parametres?.id, setParametres]);

  const preview = computeBesoins({
    id: '',
    ...form,
  });

  return (
    <div className="page">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 12, marginBottom: 16 }}>
        <h2 className="page-title">Paramètres nutritionnels</h2>
        <button type="button" className="btn secondary" onClick={handleExport}>
          Exporter CSV
        </button>
      </div>

      <section className="card form">
        <label>Poids (kg)</label>
        <input type="number" step={0.1} value={form.poids} onChange={(e) => setForm((f) => ({ ...f, poids: Number(e.target.value) }))} />
        <label>Taille (cm)</label>
        <input type="number" value={form.taille} onChange={(e) => setForm((f) => ({ ...f, taille: Number(e.target.value) }))} />
        <label>Âge</label>
        <input type="number" value={form.age} onChange={(e) => setForm((f) => ({ ...f, age: Number(e.target.value) }))} />
        <label>Sexe</label>
        <select value={form.sexe} onChange={(e) => setForm((f) => ({ ...f, sexe: e.target.value as 'homme' | 'femme' }))}>
          <option value="homme">Homme</option>
          <option value="femme">Femme</option>
        </select>
        <label>Activité</label>
        <select value={form.niveauActivite} onChange={(e) => setForm((f) => ({ ...f, niveauActivite: e.target.value as ParametresNutritionnels['niveauActivite'] }))}>
          <option value="sedentaire">Sédentaire</option>
          <option value="leger">Léger</option>
          <option value="modere">Modéré</option>
          <option value="intense">Intense</option>
          <option value="tres_intense">Très intense</option>
        </select>
        <label>Objectif</label>
        <select value={form.objectif} onChange={(e) => setForm((f) => ({ ...f, objectif: e.target.value as ParametresNutritionnels['objectif'] }))}>
          <option value="perte">Perte</option>
          <option value="maintien">Maintien</option>
          <option value="prise">Prise</option>
        </select>
        <label>Protéines (g/kg)</label>
        <input type="number" step={0.1} value={form.proteinesParKg} onChange={(e) => setForm((f) => ({ ...f, proteinesParKg: Number(e.target.value) }))} />
        <button type="button" className="btn primary" onClick={handleSave}>
          Enregistrer
        </button>
      </section>

      <section className="card">
        <h3>Besoins calculés (aperçu)</h3>
        <div className="macro-row calories">
          <div className="label">Calories</div>
          <div className="value">{Math.round(preview.caloriesQuotidiennes ?? 0)} kcal/jour</div>
        </div>
        <div className="macro-row proteines">
          <div className="label">Protéines</div>
          <div className="value">{Math.round(preview.objectifProteinesGrammes ?? 0)} g</div>
        </div>
        <div className="macro-row lipides">
          <div className="label">Lipides</div>
          <div className="value">{Math.round(preview.objectifLipidesGrammes ?? 0)} g</div>
        </div>
        <div className="macro-row glucides">
          <div className="label">Glucides</div>
          <div className="value">{Math.round(preview.objectifGlucidesGrammes ?? 0)} g</div>
        </div>
      </section>
    </div>
  );
}
