import { useState } from 'react';
import type { Repas, RepasAliment, Aliment } from '../types';

interface RepasFormProps {
  repas?: Repas | null;
  aliments: Aliment[];
  onSave: (r: Repas) => void;
  onCancel: () => void;
}

export function RepasForm({ repas, aliments, onSave, onCancel }: RepasFormProps) {
  const [nom, setNom] = useState(repas?.nom ?? '');
  const [lignes, setLignes] = useState<{ alimentId: string; quantite: number }[]>(() =>
    repas?.aliments.map((a) => ({ alimentId: a.alimentId, quantite: a.quantite })) ?? []
  );

  const addLigne = () => {
    setLignes((prev) => [...prev, { alimentId: aliments[0]?.id ?? '', quantite: 100 }]);
  };

  const updateLigne = (index: number, field: 'alimentId' | 'quantite', value: string | number) => {
    setLignes((prev) => {
      const next = [...prev];
      if (field === 'alimentId') next[index].alimentId = value as string;
      else next[index].quantite = Number(value) || 0;
      return next;
    });
  };

  const removeLigne = (index: number) => {
    setLignes((prev) => prev.filter((_, i) => i !== index));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!nom.trim()) return;
    const alimentsRepas: RepasAliment[] = lignes
      .filter((l) => l.alimentId && l.quantite > 0)
      .map((l) => ({ alimentId: l.alimentId, quantite: l.quantite }));
    onSave({
      id: repas?.id ?? crypto.randomUUID(),
      nom: nom.trim(),
      aliments: alimentsRepas,
      createdAt: repas?.createdAt ?? new Date().toISOString(),
    });
  };

  return (
    <div className="modal-overlay" onClick={onCancel}>
      <div className="modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 480 }}>
        <div className="modal-header">
          <h3>{repas ? 'Modifier le repas' : 'Nouveau repas'}</h3>
          <button type="button" className="btn icon secondary" onClick={onCancel} aria-label="Fermer">×</button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            <label>Nom du repas *</label>
            <input value={nom} onChange={(e) => setNom(e.target.value)} required placeholder="Ex: Petit-déjeuner" />
            <label>Ingrédients (aliment + quantité en g/ml pour 100)</label>
            {lignes.map((l, i) => (
              <div key={i} style={{ display: 'flex', gap: 8, marginBottom: 8, alignItems: 'center' }}>
                <select
                  value={l.alimentId}
                  onChange={(e) => updateLigne(i, 'alimentId', e.target.value)}
                  style={{ flex: 1 }}
                >
                  <option value="">— Choisir —</option>
                  {aliments.map((a) => (
                    <option key={a.id} value={a.id}>{a.nom}</option>
                  ))}
                </select>
                <input
                  type="number"
                  min={1}
                  step={1}
                  value={l.quantite || ''}
                  onChange={(e) => updateLigne(i, 'quantite', e.target.value)}
                  placeholder="qte"
                  style={{ width: 80 }}
                />
                <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>pour 100</span>
                <button type="button" className="btn icon danger" onClick={() => removeLigne(i)}>−</button>
              </div>
            ))}
            <button type="button" className="btn secondary" onClick={addLigne} style={{ marginTop: 8 }}>
              + Ajouter un ingrédient
            </button>
          </div>
          <div className="modal-footer">
            <button type="button" className="btn secondary" onClick={onCancel}>Annuler</button>
            <button type="submit" className="btn primary">Enregistrer</button>
          </div>
        </form>
      </div>
    </div>
  );
}
