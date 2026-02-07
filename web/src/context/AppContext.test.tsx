import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, act } from '@testing-library/react';
import { AppProvider, useApp } from './AppContext';

function Consumer() {
  const app = useApp();
  return (
    <div>
      <span data-testid="aliments">{app.aliments.length}</span>
      <span data-testid="repas">{app.repas.length}</span>
      <span data-testid="parametres">{app.parametres ? 'set' : 'null'}</span>
      <button type="button" onClick={() => app.setAliments([{ id: 'a1', nom: 'A', unite: 'g', prixUnitaire: 0, devise: 'EUR', gestionStock: false, quantiteStock: 0, quantiteAchatParDefaut: 1000, calories: 0, proteines: 0, lipides: 0, glucides: 0 }])}>Set aliments</button>
      <button type="button" onClick={() => app.setRepas([{ id: 'r1', nom: 'R', aliments: [] }])}>Set repas</button>
      <button type="button" onClick={() => app.setJoursRepas([{ id: 'j1', date: '2025-02-07', repasId: 'r1', heure: 12, minute: 0 }])}>Set joursRepas</button>
      <button type="button" onClick={() => app.setEntrainements([{ id: 'e1', date: '2025-02-07', type: 'cardio', dureeMinutes: 30, distance: 5, caloriesBrulees: 200 }])}>Set entrainements</button>
      <button type="button" onClick={() => app.setMesures([{ id: 'm1', date: '2025-02-07', poids: 70 }])}>Set mesures</button>
      <button type="button" onClick={() => app.setParametres({ id: 'p1', poids: 70, taille: 175, age: 30, sexe: 'homme', niveauActivite: 'modere', objectif: 'maintien', objectifProteines: 30, objectifLipides: 25, objectifGlucides: 45, proteinesParKg: 1.6 })}>Set parametres</button>
      <button type="button" onClick={() => app.load()}>Load</button>
    </div>
  );
}

describe('AppContext', () => {
  beforeEach(() => {
    const store: Record<string, string> = {
      pigeon_aliments: '[]',
      pigeon_repas: '[]',
      pigeon_jours_repas: '[]',
      pigeon_entrainements: '[]',
      pigeon_mesures: '[]',
      pigeon_parametres: 'null',
    };
    vi.stubGlobal('localStorage', {
      getItem: (key: string) => store[key] ?? null,
      setItem: (key: string, value: string) => { store[key] = value; },
      removeItem: (key: string) => { delete store[key]; },
      clear: () => {},
      length: 0,
      key: () => null,
    });
  });

  it('AppProvider provides initial data from storage', () => {
    render(
      <AppProvider>
        <Consumer />
      </AppProvider>
    );
    expect(screen.getByTestId('aliments').textContent).toBe('0');
  });

  it('setAliments updates state and persists', async () => {
    render(
      <AppProvider>
        <Consumer />
      </AppProvider>
    );
    await act(async () => { screen.getByText('Set aliments').click(); });
    expect(screen.getByTestId('aliments').textContent).toBe('1');
  });

  it('setRepas updates state', async () => {
    render(<AppProvider><Consumer /></AppProvider>);
    await act(async () => { screen.getByText('Set repas').click(); });
    expect(screen.getByTestId('repas').textContent).toBe('1');
  });

  it('setJoursRepas, setEntrainements, setMesures update state', async () => {
    render(<AppProvider><Consumer /></AppProvider>);
    await act(async () => { screen.getByText('Set joursRepas').click(); });
    await act(async () => { screen.getByText('Set entrainements').click(); });
    await act(async () => { screen.getByText('Set mesures').click(); });
    expect(screen.getByTestId('repas').textContent).toBe('0');
  });

  it('setParametres updates state', async () => {
    render(<AppProvider><Consumer /></AppProvider>);
    expect(screen.getByTestId('parametres').textContent).toBe('null');
    await act(async () => { screen.getByText('Set parametres').click(); });
    expect(screen.getByTestId('parametres').textContent).toBe('set');
  });

  it('useApp throws when used outside AppProvider', () => {
    const Throw = () => {
      useApp();
      return null;
    };
    expect(() => render(<Throw />)).toThrow('useApp must be used within AppProvider');
  });
});
