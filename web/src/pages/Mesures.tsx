import { useCallback, useState } from 'react';
import { useApp } from '../context/AppContext';
import { exportMesuresCSV } from '../services/csv';
import type { MesuresCorporelles } from '../types';

export function Mesures() {
  const { mesures, setMesures } = useApp();
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({
    date: new Date().toISOString().slice(0, 10),
    poids: 70,
    tauxGraisse: '' as number | '',
    notes: '',
  });

  const handleExport = useCallback(() => {
    exportMesuresCSV(mesures);
  }, [mesures]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const m: MesuresCorporelles = {
      id: crypto.randomUUID(),
      date: form.date,
      poids: form.poids,
      tauxGraisse: form.tauxGraisse === '' ? undefined : form.tauxGraisse,
      notes: form.notes || undefined,
    };
    setMesures([...mesures, m]);
    setShowForm(false);
    setForm({ date: new Date().toISOString().slice(0, 10), poids: form.poids, tauxGraisse: '', notes: '' });
  };

  const handleDelete = (id: string) => {
    if (!window.confirm('Supprimer cette mesure ?')) return;
    setMesures(mesures.filter((m) => m.id !== id));
  };

  return (
    <div className="page">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 12, marginBottom: 16 }}>
        <h2 className="page-title">Mesures corporelles</h2>
        <div style={{ display: 'flex', gap: 8 }}>
          <button type="button" className="btn secondary" onClick={handleExport}>
            Exporter CSV
          </button>
          <button type="button" className="btn primary" onClick={() => setShowForm(true)}>
            + Ajouter
          </button>
        </div>
      </div>

      {mesures.length === 0 ? (
        <div className="empty-state">
          <p>Aucune mesure. Cliquez sur « Ajouter » pour enregistrer poids et optionnellement % graisse.</p>
        </div>
      ) : (
        <div>
          {[...mesures]
            .sort((a, b) => b.date.localeCompare(a.date))
            .map((m) => (
              <div key={m.id} className="aliment-card">
                <div className="name">{m.date}</div>
                <div className="meta">
                  <strong>{m.poids} kg</strong>
                  {m.tauxGraisse != null && ` · ${m.tauxGraisse}% graisse`}
                  {m.notes && ` · ${m.notes}`}
                </div>
                <div className="actions">
                  <button type="button" className="btn icon danger" onClick={() => handleDelete(m.id)} title="Supprimer">🗑️</button>
                </div>
              </div>
            ))}
        </div>
      )}

      {showForm && (
        <div className="modal-overlay" onClick={() => setShowForm(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Nouvelle mesure</h3>
              <button type="button" className="btn icon secondary" onClick={() => setShowForm(false)}>×</button>
            </div>
            <form onSubmit={handleSubmit}>
              <div className="modal-body">
                <label>Date</label>
                <input type="date" value={form.date} onChange={(e) => setForm((f) => ({ ...f, date: e.target.value }))} required />
                <label>Poids (kg)</label>
                <input type="number" step={0.1} value={form.poids} onChange={(e) => setForm((f) => ({ ...f, poids: Number(e.target.value) || 0 }))} required />
                <label>Taux de graisse (%)</label>
                <input type="number" step={0.1} value={form.tauxGraisse} onChange={(e) => setForm((f) => ({ ...f, tauxGraisse: e.target.value ? Number(e.target.value) : '' }))} placeholder="Optionnel" />
                <label>Notes</label>
                <input value={form.notes} onChange={(e) => setForm((f) => ({ ...f, notes: e.target.value }))} placeholder="Optionnel" />
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
  );
}
