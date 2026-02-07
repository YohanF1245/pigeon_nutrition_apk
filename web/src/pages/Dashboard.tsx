import { Link } from 'react-router-dom';
import { useMemo, useState, useCallback } from 'react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  ReferenceLine,
} from 'recharts';
import { useApp } from '../context/AppContext';
import { exportAllZIP } from '../services/csv';
import { macrosPourDate, nutritionHistory } from '../utils/nutrition';

const PERIODS = [7, 14, 30];

export function Dashboard() {
  const { aliments, repas, joursRepas, entrainements, mesures, parametres } = useApp();
  const [period, setPeriod] = useState(7);

  const today = useMemo(() => new Date().toISOString().slice(0, 10), []);
  const macrosJour = useMemo(
    () => macrosPourDate(today, joursRepas, repas, aliments),
    [today, joursRepas, repas, aliments]
  );
  const history = useMemo(
    () => nutritionHistory(period, joursRepas, repas, aliments),
    [period, joursRepas, repas, aliments]
  );
  const chartData = useMemo(() => {
    const obj = parametres
      ? {
          calories: parametres.caloriesQuotidiennes ?? 0,
          proteines: parametres.objectifProteinesGrammes ?? 0,
          lipides: parametres.objectifLipidesGrammes ?? 0,
          glucides: parametres.objectifGlucidesGrammes ?? 0,
        }
      : { calories: 0, proteines: 0, lipides: 0, glucides: 0 };
    return history.map((d) => ({
      date: d.date.slice(5),
      calories: d.calories - obj.calories,
      proteines: d.proteines - obj.proteines,
      lipides: d.lipides - obj.lipides,
      glucides: d.glucides - obj.glucides,
    }));
  }, [history, parametres]);

  const handleExportZip = useCallback(async () => {
    await exportAllZIP({ aliments, repas, joursRepas, entrainements, mesures, parametres });
  }, [aliments, repas, joursRepas, entrainements, mesures, parametres]);

  const alimentsEnRupture = aliments.filter(
    (a) => a.gestionStock && a.seuilAlerte != null && a.quantiteStock <= a.seuilAlerte
  );
  const repasAujourdhui = joursRepas.filter((j) => j.date === today);

  return (
    <div className="page">
      <h2 className="page-title">Tableau de bord</h2>

      {parametres && (
        <section className="card">
          <h3>Macronutriments du jour</h3>
          {[
            {
              key: 'calories',
              label: 'Calories',
              actuel: macrosJour.calories,
              objectif: parametres.caloriesQuotidiennes ?? 0,
              unite: 'kcal',
            },
            {
              key: 'proteines',
              label: 'Protéines',
              actuel: macrosJour.proteines,
              objectif: parametres.objectifProteinesGrammes ?? 0,
              unite: 'g',
            },
            {
              key: 'lipides',
              label: 'Lipides',
              actuel: macrosJour.lipides,
              objectif: parametres.objectifLipidesGrammes ?? 0,
              unite: 'g',
            },
            {
              key: 'glucides',
              label: 'Glucides',
              actuel: macrosJour.glucides,
              objectif: parametres.objectifGlucidesGrammes ?? 0,
              unite: 'g',
            },
          ].map(({ key, label, actuel, objectif, unite }) => {
            const progress = objectif > 0 ? Math.min(actuel / objectif, 1.5) : 0;
            return (
              <div key={key} className={`macro-row ${key}`}>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span className="label">{label}</span>
                  <span className="value">
                    {actuel.toFixed(0)} / {objectif.toFixed(0)} {unite}
                  </span>
                </div>
                <div className="progress-wrap">
                  <div
                    className="progress-fill"
                    style={{ width: `${Math.min(progress * 100, 100)}%` }}
                  />
                </div>
              </div>
            );
          })}
        </section>
      )}

      {parametres && history.some((d) => d.calories > 0 || d.proteines > 0) && (
        <section className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
            <h3 style={{ margin: 0 }}>Évolution des écarts (vs objectifs)</h3>
            <select
              value={period}
              onChange={(e) => setPeriod(Number(e.target.value))}
              style={{ padding: '6px 10px', borderRadius: 6, border: '1px solid var(--border)' }}
            >
              {PERIODS.map((d) => (
                <option key={d} value={d}>{d} jours</option>
              ))}
            </select>
          </div>
          <div className="chart-legend">
            <span><span className="dot" style={{ background: '#1976d2' }} /> Calories</span>
            <span><span className="dot" style={{ background: '#c62828' }} /> Protéines</span>
            <span><span className="dot" style={{ background: '#ef6c00' }} /> Lipides</span>
            <span><span className="dot" style={{ background: '#2e7d32' }} /> Glucides</span>
          </div>
          <ResponsiveContainer width="100%" height={220}>
            <LineChart data={chartData} margin={{ top: 5, right: 10, left: 0, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
              <XAxis dataKey="date" tick={{ fontSize: 11 }} />
              <YAxis tick={{ fontSize: 10 }} />
              <Tooltip formatter={(v) => (v != null ? Number(v).toFixed(0) : '')} />
              <ReferenceLine y={0} stroke="#666" strokeDasharray="2 2" />
              <Line type="monotone" dataKey="calories" stroke="#1976d2" strokeWidth={2} dot={false} name="Calories" />
              <Line type="monotone" dataKey="proteines" stroke="#c62828" strokeWidth={2} dot={false} name="Protéines" />
              <Line type="monotone" dataKey="lipides" stroke="#ef6c00" strokeWidth={2} dot={false} name="Lipides" />
              <Line type="monotone" dataKey="glucides" stroke="#2e7d32" strokeWidth={2} dot={false} name="Glucides" />
              <Legend wrapperStyle={{ fontSize: '0.75rem' }} />
            </LineChart>
          </ResponsiveContainer>
        </section>
      )}

      <section className="card">
        <h3>Résumé</h3>
        <ul className="list">
          <li className="list-item">Aliments : <strong>{aliments.length}</strong></li>
          <li className="list-item">Repas : <strong>{repas.length}</strong></li>
          <li className="list-item">Repas aujourd&apos;hui : <strong>{repasAujourdhui.length}</strong></li>
          {alimentsEnRupture.length > 0 && (
            <li className="list-item alert">En rupture : <strong>{alimentsEnRupture.length}</strong> aliments</li>
          )}
        </ul>
      </section>

      <section className="card">
        <h3>Export / Import</h3>
        <p style={{ margin: '0 0 12px', fontSize: '0.9rem', color: 'var(--text-muted)' }}>
          Exportez toutes les données en ZIP (CSV) pour analyse dans Excel ou Python.
        </p>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 10 }}>
          <button type="button" className="btn primary" onClick={handleExportZip}>
            Télécharger export ZIP
          </button>
          <Link to="/import" className="btn secondary">Importer un ZIP</Link>
        </div>
      </section>
    </div>
  );
}
