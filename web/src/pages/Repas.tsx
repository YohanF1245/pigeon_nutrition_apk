import { useCallback, useMemo, useState } from 'react';
import { useApp } from '../context/AppContext';
import { exportRepasCSV, exportRepasAlimentsCSV } from '../services/csv';
import { RepasForm } from '../components/RepasForm';
import { nutrimentsRepas } from '../utils/nutrition';
import type { Repas as RepasType } from '../types';

const today = () => new Date().toISOString().slice(0, 10);

export function Repas() {
  const { aliments, repas, joursRepas, setRepas, setJoursRepas } = useApp();
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<RepasType | null>(null);
  const [datePlan, setDatePlan] = useState(today());

  const macrosJour = useMemo(
    () => {
      const jrs = joursRepas.filter((j) => j.date === datePlan);
      let c = 0, p = 0, l = 0, g = 0;
      for (const jr of jrs) {
        const r = repas.find((x) => x.id === jr.repasId);
        if (!r) continue;
        const n = nutrimentsRepas(r, aliments);
        c += n.calories;
        p += n.proteines;
        l += n.lipides;
        g += n.glucides;
      }
      return { calories: c, proteines: p, lipides: l, glucides: g };
    },
    [datePlan, joursRepas, repas, aliments]
  );

  const repasDuJour = useMemo(
    () => joursRepas.filter((j) => j.date === datePlan).map((jr) => {
      const r = repas.find((x) => x.id === jr.repasId);
      return { ...jr, repas: r };
    }).filter((x) => x.repas),
    [datePlan, joursRepas, repas]
  );

  const handleSaveRepas = useCallback(
    (r: RepasType) => {
      const idx = repas.findIndex((x) => x.id === r.id);
      const next = [...repas];
      if (idx >= 0) next[idx] = r;
      else next.push(r);
      setRepas(next);
      setEditing(null);
      setShowForm(false);
    },
    [repas, setRepas]
  );

  const handleDeleteRepas = useCallback(
    (id: string) => {
      if (!window.confirm('Supprimer ce repas ? Les planifications associées seront aussi supprimées.')) return;
      setRepas(repas.filter((r) => r.id !== id));
      setJoursRepas(joursRepas.filter((j) => j.repasId !== id));
    },
    [repas, joursRepas, setRepas, setJoursRepas]
  );

  const handlePlanifier = (repasId: string) => {
    const repasExiste = repas.find((r) => r.id === repasId);
    if (!repasExiste) return;
    const now = new Date();
    setJoursRepas([
      ...joursRepas,
      {
        id: crypto.randomUUID(),
        date: datePlan,
        repasId,
        heure: now.getHours(),
        minute: now.getMinutes(),
      },
    ]);
  };

  const handleUnplanifier = (jourRepasId: string) => {
    setJoursRepas(joursRepas.filter((j) => j.id !== jourRepasId));
  };

  return (
    <div className="page">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 12, marginBottom: 16 }}>
        <h2 className="page-title">Repas</h2>
        <div style={{ display: 'flex', gap: 8 }}>
          <button type="button" className="btn secondary" onClick={() => exportRepasCSV(repas)}>Exporter repas</button>
          <button type="button" className="btn secondary" onClick={() => exportRepasAlimentsCSV(repas)}>Exporter repas_aliments</button>
          <button type="button" className="btn primary" onClick={() => { setEditing(null); setShowForm(true); }}>+ Ajouter repas</button>
        </div>
      </div>

      <section className="card">
        <h3>Macros du jour</h3>
        <p style={{ margin: 0, fontSize: '0.9rem' }}>
          <strong>Date :</strong>{' '}
          <input
            type="date"
            value={datePlan}
            onChange={(e) => setDatePlan(e.target.value)}
            style={{ padding: 6, borderRadius: 6, border: '1px solid var(--border)' }}
          />
        </p>
        <p style={{ margin: '8px 0 0', color: 'var(--text-muted)', fontSize: '0.9rem' }}>
          {macrosJour.calories.toFixed(0)} kcal · P: {macrosJour.proteines.toFixed(0)}g · L: {macrosJour.lipides.toFixed(0)}g · G: {macrosJour.glucides.toFixed(0)}g
        </p>
      </section>

      <section className="card">
        <h3>Repas planifiés ce jour</h3>
        {repasDuJour.length === 0 ? (
          <p className="empty-state" style={{ padding: 16 }}>Aucun repas planifié. Ajoutez-en ci‑dessous.</p>
        ) : (
          <ul className="list">
            {repasDuJour.map((jr) => (
              <li key={jr.id} className="list-item" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span><strong>{jr.repas?.nom}</strong> — {jr.heure}h{String(jr.minute).padStart(2, '0')}</span>
                <button type="button" className="btn icon secondary" onClick={() => handleUnplanifier(jr.id)} title="Retirer">×</button>
              </li>
            ))}
          </ul>
        )}
        <p style={{ marginTop: 12, fontSize: '0.85rem', color: 'var(--text-muted)' }}>Planifier un repas :</p>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginTop: 8 }}>
          {repas.map((r) => (
            <button key={r.id} type="button" className="btn secondary" onClick={() => handlePlanifier(r.id)}>
              + {r.nom}
            </button>
          ))}
          {repas.length === 0 && <span style={{ color: 'var(--text-muted)' }}>Créez d’abord un repas ci‑dessous.</span>}
        </div>
      </section>

      <section className="card">
        <h3>Liste des repas</h3>
        {repas.length === 0 ? (
          <div className="empty-state">Aucun repas. Cliquez sur « Ajouter repas ».</div>
        ) : (
          <ul className="list">
            {repas.map((r) => {
              const n = nutrimentsRepas(r, aliments);
              return (
                <li key={r.id} className="list-item" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 8 }}>
                  <span><strong>{r.nom}</strong> — {r.aliments.length} ingrédient(s) · {n.calories.toFixed(0)} kcal</span>
                  <span>
                    <button type="button" className="btn icon secondary" onClick={() => { setEditing(r); setShowForm(true); }}>✏️</button>
                    <button type="button" className="btn icon danger" onClick={() => handleDeleteRepas(r.id)}>🗑️</button>
                  </span>
                </li>
              );
            })}
          </ul>
        )}
      </section>

      {showForm && (
        <RepasForm
          repas={editing}
          aliments={aliments}
          onSave={handleSaveRepas}
          onCancel={() => { setShowForm(false); setEditing(null); }}
        />
      )}
    </div>
  );
}
