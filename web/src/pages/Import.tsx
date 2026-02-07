import { Link } from 'react-router-dom';
import { useCallback, useRef, useState } from 'react';
import { useApp } from '../context/AppContext';
import { importFromZIP, type ImportResult } from '../services/csv';

export function ImportPage() {
  const { load } = useApp();
  const [result, setResult] = useState<ImportResult | null>(null);
  const [merge, setMerge] = useState(true);
  const inputRef = useRef<HTMLInputElement>(null);

  const handleFile = useCallback(
    async (e: React.ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0];
      if (!file) return;
      setResult(null);
      try {
        const res = await importFromZIP(file, merge);
        setResult(res);
        load();
      } catch (err) {
        setResult({
          ok: false,
          aliments: 0,
          repas: 0,
          repasAliments: 0,
          joursRepas: 0,
          entrainements: 0,
          mesures: 0,
          parametres: 0,
          errors: [err instanceof Error ? err.message : String(err)],
        });
      }
      e.target.value = '';
    },
    [merge, load]
  );

  return (
    <div className="page">
      <h2 className="page-title">Importer un export ZIP</h2>
      <p style={{ margin: '0 0 16px', color: 'var(--text-muted)', fontSize: '0.95rem' }}>
        Choisissez un fichier ZIP généré par « Télécharger export ZIP » (ou contenant les CSV attendus).
      </p>
      <section className="card">
        <label style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer', marginBottom: 12 }}>
          <input type="checkbox" checked={merge} onChange={(e) => setMerge(e.target.checked)} />
          Fusionner avec les données existantes (décoché = tout remplacer)
        </label>
        <input ref={inputRef} type="file" accept=".zip" onChange={handleFile} style={{ display: 'block' }} />
      </section>
      {result && (
        <section className={`card ${result.ok ? '' : 'error'}`}>
          <h3>{result.ok ? 'Import réussi' : 'Import avec erreurs'}</h3>
          <ul className="list">
            <li className="list-item">Aliments : {result.aliments}</li>
            <li className="list-item">Repas : {result.repas} (lignes repas_aliments : {result.repasAliments})</li>
            <li className="list-item">Jours repas : {result.joursRepas}</li>
            <li className="list-item">Entraînements : {result.entrainements}</li>
            <li className="list-item">Mesures : {result.mesures}</li>
            <li className="list-item">Paramètres : {result.parametres}</li>
          </ul>
          {result.errors.length > 0 && (
            <ul className="errors">
              {result.errors.map((err, i) => (
                <li key={i}>{err}</li>
              ))}
            </ul>
          )}
          <p style={{ marginTop: 12 }}>
            <Link to="/" className="btn primary">Retour au tableau de bord</Link>
          </p>
        </section>
      )}
    </div>
  );
}
