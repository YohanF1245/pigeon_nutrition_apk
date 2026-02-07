import { useCallback, useState } from 'react';
import { useApp } from '../context/AppContext';
import { exportEntrainementsCSV } from '../services/csv';
import type { Entrainement } from '../types';

export function Entrainements() {
  const { entrainements, setEntrainements } = useApp();
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({
    date: new Date().toISOString().slice(0, 10),
    type: 'cardio' as 'cardio' | 'divers',
    dureeMinutes: 30,
    distance: 0,
    caloriesBrulees: 0,
    activite: 'Marche',
  });

  const handleExport = useCallback(() => {
    exportEntrainementsCSV(entrainements);
  }, [entrainements]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const newEnt: Entrainement =
      form.type === 'cardio'
        ? {
            id: crypto.randomUUID(),
            date: form.date,
            type: 'cardio',
            dureeMinutes: form.dureeMinutes,
            distance: form.distance,
            caloriesBrulees: form.caloriesBrulees,
          }
        : {
            id: crypto.randomUUID(),
            date: form.date,
            type: 'divers',
            dureeMinutes: form.dureeMinutes,
            activite: form.activite,
            distance: form.distance || undefined,
            caloriesBrulees: form.caloriesBrulees || undefined,
          };
    setEntrainements([...entrainements, newEnt]);
    setShowForm(false);
    setForm({ date: new Date().toISOString().slice(0, 10), type: 'cardio', dureeMinutes: 30, distance: 0, caloriesBrulees: 0, activite: 'Marche' });
  };

  const handleDelete = (id: string) => {
    if (!window.confirm('Supprimer cet entraînement ?')) return;
    setEntrainements(entrainements.filter((e) => e.id !== id));
  };

  return (
    <>
    <div className="page">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 12, marginBottom: 16 }}>
        <h2 className="page-title">Entraînements</h2>
        <div style={{ display: 'flex', gap: 8 }}>
          <button type="button" className="btn secondary" onClick={handleExport}>
            Exporter CSV
          </button>
          <button type="button" className="btn primary" onClick={() => setShowForm(true)}>
            + Ajouter
          </button>
        </div>
      </div>

      {entrainements.length === 0 ? (
        <div className="empty-state">
          <p>Aucun entraînement. Cliquez sur « Ajouter » pour enregistrer une séance.</p>
        </div>
      ) : (
        <div>
          {[...entrainements]
            .sort((a, b) => b.date.localeCompare(a.date))
            .map((e) => (
              <div key={e.id} className="aliment-card">
                <div className="name">
                  {e.date} — {e.type === 'cardio' ? 'Cardio' : e.type === 'musculation' ? 'Musculation' : e.activite}
                </div>
                <div className="meta">
                  {e.dureeMinutes} min
                  {e.type === 'cardio' && e.distance > 0 && ` · ${e.distance} km`}
                  {e.type === 'cardio' && e.caloriesBrulees > 0 && ` · ${e.caloriesBrulees} kcal`}
                </div>
                <div className="actions">
                  <button type="button" className="btn icon danger" onClick={() => handleDelete(e.id)} title="Supprimer">🗑️</button>
                </div>
              </div>
            ))}
        </div>
      )}

      {showForm && (
        <div className="modal-overlay" onClick={() => setShowForm(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Nouvel entraînement</h3>
              <button type="button" className="btn icon secondary" onClick={() => setShowForm(false)}>×</button>
            </div>
            <form onSubmit={handleSubmit}>
              <div className="modal-body">
                <label>Date</label>
                <input type="date" value={form.date} onChange={(e) => setForm((f) => ({ ...f, date: e.target.value }))} required />
                <label>Type</label>
                <select value={form.type} onChange={(e) => setForm((f) => ({ ...f, type: e.target.value as 'cardio' | 'divers' }))}>
                  <option value="cardio">Cardio</option>
                  <option value="divers">Divers</option>
                </select>
                <label>Durée (min)</label>
                <input type="number" min={1} value={form.dureeMinutes} onChange={(e) => setForm((f) => ({ ...f, dureeMinutes: Number(e.target.value) || 0 }))} />
                {form.type === 'divers' && (
                  <>
                    <label>Activité</label>
                    <input value={form.activite} onChange={(e) => setForm((f) => ({ ...f, activite: e.target.value }))} placeholder="Ex: Marche" />
                  </>
                )}
                <label>Distance (km)</label>
                <input type="number" step={0.1} value={form.distance || ''} onChange={(e) => setForm((f) => ({ ...f, distance: Number(e.target.value) || 0 }))} />
                <label>Calories brûlées</label>
                <input type="number" value={form.caloriesBrulees || ''} onChange={(e) => setForm((f) => ({ ...f, caloriesBrulees: Number(e.target.value) || 0 }))} />
              </div>
              <div className="modal-footer">
                <button type="button" className="btn secondary" onClick={() => setShowForm(false)}>Annuler</button>
                <button type="submit" className="btn primary">Enregistrer</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
    </>
  );
}
