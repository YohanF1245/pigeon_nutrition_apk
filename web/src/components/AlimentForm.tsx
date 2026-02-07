import { useState, useEffect } from 'react';
import type { Aliment } from '../types';
import { getProductByBarcode } from '../services/openFoodFacts';
import { BarcodeScannerModal } from './BarcodeScannerModal';

interface AlimentFormProps {
  aliment?: Aliment | null;
  onSave: (a: Aliment) => void;
  onCancel: () => void;
}

const emptyAliment = (): Aliment => ({
  id: crypto.randomUUID(),
  nom: '',
  unite: 'g',
  prixUnitaire: 0,
  devise: 'EUR',
  gestionStock: false,
  quantiteStock: 0,
  quantiteAchatParDefaut: 100,
  calories: 0,
  proteines: 0,
  lipides: 0,
  glucides: 0,
});

export function AlimentForm({ aliment, onSave, onCancel }: AlimentFormProps) {
  const [form, setForm] = useState<Aliment>(aliment ?? emptyAliment());
  const [barcodeInput, setBarcodeInput] = useState('');
  const [barcodeLoading, setBarcodeLoading] = useState(false);
  const [barcodeError, setBarcodeError] = useState<string | null>(null);
  const [scannerOpen, setScannerOpen] = useState(false);

  useEffect(() => {
    setForm(aliment ?? emptyAliment());
  }, [aliment]);

  const handleSearchBarcode = async (overrideCode?: string) => {
    const code = (overrideCode ?? barcodeInput).trim();
    if (!code) return;
    setBarcodeError(null);
    setBarcodeLoading(true);
    try {
      const product = await getProductByBarcode(code);
      if (product) {
        setForm((f) => ({
          ...f,
          nom: product.name,
          calories: product.nutriments.calories,
          proteines: product.nutriments.proteines,
          lipides: product.nutriments.lipides,
          glucides: product.nutriments.glucides,
        }));
      } else {
        setBarcodeError('Produit non trouvé. Vérifiez le code-barres.');
      }
    } catch {
      setBarcodeError('Erreur lors de la recherche.');
    } finally {
      setBarcodeLoading(false);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.nom.trim()) return;
    onSave({ ...form, id: aliment?.id ?? form.id });
  };

  return (
    <div className="modal-overlay" onClick={onCancel}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h3>{aliment ? 'Modifier l\'aliment' : 'Nouvel aliment'}</h3>
          <button type="button" className="btn icon secondary" onClick={onCancel} aria-label="Fermer">×</button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            {!aliment && (
              <div className="card" style={{ marginBottom: 16, padding: 12, background: 'var(--bg)' }}>
                <h4 style={{ margin: '0 0 8px', fontSize: '0.9rem' }}>Rechercher par code-barres (Open Food Facts)</h4>
                <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center' }}>
                  <input
                    type="text"
                    value={barcodeInput}
                    onChange={(e) => { setBarcodeInput(e.target.value); setBarcodeError(null); }}
                    onKeyDown={(e) => e.key === 'Enter' && (e.preventDefault(), handleSearchBarcode())}
                    placeholder="Ex: 3017620422003"
                    disabled={barcodeLoading}
                    style={{ flex: 1, minWidth: 140 }}
                  />
                  <button type="button" className="btn secondary" onClick={() => setScannerOpen(true)} disabled={barcodeLoading} title="Scanner avec la caméra">
                    📷 Scanner
                  </button>
                  <button type="button" className="btn secondary" onClick={() => handleSearchBarcode()} disabled={barcodeLoading}>
                    {barcodeLoading ? 'Recherche…' : 'Rechercher'}
                  </button>
                </div>
                {barcodeError && <p style={{ margin: '8px 0 0', color: 'var(--error)', fontSize: '0.85rem' }}>{barcodeError}</p>}
              </div>
            )}
            <label>Nom *</label>
            <input
              value={form.nom}
              onChange={(e) => setForm((f) => ({ ...f, nom: e.target.value }))}
              required
              placeholder="Ex: Poulet"
            />
            <label>Unité</label>
            <select
              value={form.unite}
              onChange={(e) => setForm((f) => ({ ...f, unite: e.target.value as 'g' | 'ml' }))}
            >
              <option value="g">g</option>
              <option value="ml">ml</option>
            </select>
            <label>Calories (pour 100{form.unite})</label>
            <input
              type="number"
              step={0.1}
              value={form.calories || ''}
              onChange={(e) => setForm((f) => ({ ...f, calories: Number(e.target.value) || 0 }))}
            />
            <label>Protéines (g / 100{form.unite})</label>
            <input
              type="number"
              step={0.1}
              value={form.proteines || ''}
              onChange={(e) => setForm((f) => ({ ...f, proteines: Number(e.target.value) || 0 }))}
            />
            <label>Lipides (g / 100{form.unite})</label>
            <input
              type="number"
              step={0.1}
              value={form.lipides || ''}
              onChange={(e) => setForm((f) => ({ ...f, lipides: Number(e.target.value) || 0 }))}
            />
            <label>Glucides (g / 100{form.unite})</label>
            <input
              type="number"
              step={0.1}
              value={form.glucides || ''}
              onChange={(e) => setForm((f) => ({ ...f, glucides: Number(e.target.value) || 0 }))}
            />
            <label style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 12 }}>
              <input
                type="checkbox"
                checked={form.gestionStock}
                onChange={(e) => setForm((f) => ({ ...f, gestionStock: e.target.checked }))}
              />
              Gestion du stock
            </label>
            {form.gestionStock && (
              <>
                <label>Quantité en stock</label>
                <input
                  type="number"
                  step={0.1}
                  value={form.quantiteStock ?? ''}
                  onChange={(e) => setForm((f) => ({ ...f, quantiteStock: Number(e.target.value) || 0 }))}
                />
                <label>Seuil d&apos;alerte</label>
                <input
                  type="number"
                  step={0.1}
                  value={form.seuilAlerte ?? ''}
                  onChange={(e) => setForm((f) => ({ ...f, seuilAlerte: e.target.value ? Number(e.target.value) : undefined }))}
                  placeholder="Optionnel"
                />
              </>
            )}
          </div>
          <div className="modal-footer">
            <button type="button" className="btn secondary" onClick={onCancel}>Annuler</button>
            <button type="submit" className="btn primary">Enregistrer</button>
          </div>
        </form>
      </div>
      {!aliment && (
        <BarcodeScannerModal
          open={scannerOpen}
          onClose={() => setScannerOpen(false)}
          onScan={(barcode) => {
            try {
              setBarcodeInput(barcode);
              setBarcodeError(null);
              handleSearchBarcode(barcode);
            } catch (e) {
              setBarcodeError('Erreur après le scan.');
            }
          }}
        />
      )}
    </div>
  );
}
