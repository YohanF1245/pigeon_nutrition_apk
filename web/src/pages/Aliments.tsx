import { useCallback, useState } from 'react';
import { useApp } from '../context/AppContext';
import { exportAlimentsCSV } from '../services/csv';
import { AlimentForm } from '../components/AlimentForm';
import type { Aliment } from '../types';

export function Aliments() {
  const { aliments, setAliments } = useApp();
  const [editing, setEditing] = useState<Aliment | null>(null);
  const [showForm, setShowForm] = useState(false);

  const handleExport = useCallback(() => {
    exportAlimentsCSV(aliments);
  }, [aliments]);

  const handleSave = useCallback(
    (a: Aliment) => {
      const idx = aliments.findIndex((x) => x.id === a.id);
      const next = [...aliments];
      if (idx >= 0) next[idx] = a;
      else next.push(a);
      setAliments(next);
      setEditing(null);
      setShowForm(false);
    },
    [aliments, setAliments]
  );

  const handleDelete = useCallback(
    (id: string) => {
      if (!window.confirm('Supprimer cet aliment ?')) return;
      setAliments(aliments.filter((a) => a.id !== id));
    },
    [aliments, setAliments]
  );

  return (
    <div className="page">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 12, marginBottom: 16 }}>
        <h2 className="page-title">Aliments</h2>
        <div style={{ display: 'flex', gap: 8 }}>
          <button type="button" className="btn secondary" onClick={handleExport}>
            Exporter CSV
          </button>
          <button type="button" className="btn primary" onClick={() => { setEditing(null); setShowForm(true); }}>
            + Ajouter
          </button>
        </div>
      </div>

      {aliments.length === 0 ? (
        <div className="empty-state">
          <p>Aucun aliment. Cliquez sur « Ajouter » pour en créer un, ou importez un CSV/ZIP.</p>
        </div>
      ) : (
        <div>
          {aliments.map((a) => (
            <div key={a.id} className="aliment-card">
              <div className="name">{a.nom}</div>
              <div className="meta">
                {a.gestionStock && (
                  <span className={a.seuilAlerte != null && a.quantiteStock <= a.seuilAlerte ? 'stock-warn' : ''}>
                    📦 {a.quantiteStock.toFixed(1)} {a.unitePortionLabel ?? a.unite}
                    {a.seuilAlerte != null && ` (min: ${a.seuilAlerte})`}
                  </span>
                )}
                {!a.gestionStock && <span>—</span>}
              </div>
              <div className="nutrition-boxes">
                <div className="nutrition-box calories"><span className="label">Cal</span><span className="val">{a.calories.toFixed(0)}</span></div>
                <div className="nutrition-box proteines"><span className="label">P</span><span className="val">{a.proteines.toFixed(1)}g</span></div>
                <div className="nutrition-box lipides"><span className="label">L</span><span className="val">{a.lipides.toFixed(1)}g</span></div>
                <div className="nutrition-box glucides"><span className="label">G</span><span className="val">{a.glucides.toFixed(1)}g</span></div>
              </div>
              <div className="actions">
                <button type="button" className="btn icon secondary" onClick={() => { setEditing(a); setShowForm(true); }} title="Modifier">✏️</button>
                <button type="button" className="btn icon danger" onClick={() => handleDelete(a.id)} title="Supprimer">🗑️</button>
              </div>
            </div>
          ))}
        </div>
      )}

      {showForm && (
        <AlimentForm
          aliment={editing}
          onSave={handleSave}
          onCancel={() => { setShowForm(false); setEditing(null); }}
        />
      )}
    </div>
  );
}
