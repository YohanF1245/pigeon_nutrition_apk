import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { AppProvider } from './context/AppContext';
import { Layout } from './components/Layout';
import { Dashboard } from './pages/Dashboard';
import { Aliments } from './pages/Aliments';
import { Repas } from './pages/Repas';
import { Entrainements } from './pages/Entrainements';
import { Mesures } from './pages/Mesures';
import { Parametres } from './pages/Parametres';
import { ImportPage } from './pages/Import';

function TestApp({ initialEntry = '/' }: { initialEntry?: string }) {
  return (
    <MemoryRouter initialEntries={[initialEntry]}>
      <AppProvider>
        <Routes>
          <Route path="/" element={<Layout />}>
            <Route index element={<Dashboard />} />
            <Route path="aliments" element={<Aliments />} />
            <Route path="repas" element={<Repas />} />
            <Route path="entrainements" element={<Entrainements />} />
            <Route path="mesures" element={<Mesures />} />
            <Route path="parametres" element={<Parametres />} />
            <Route path="import" element={<ImportPage />} />
          </Route>
        </Routes>
      </AppProvider>
    </MemoryRouter>
  );
}

describe('App integration', () => {
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

  it('renders layout and dashboard at /', () => {
    render(<TestApp />);
    expect(screen.getByText('Pigeon Nutrition')).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: 'Tableau de bord' })).toBeInTheDocument();
  });

  it('renders Aliments page at /aliments', () => {
    render(<TestApp initialEntry="/aliments" />);
    expect(screen.getByRole('heading', { name: 'Aliments' })).toBeInTheDocument();
    expect(screen.getByText(/Aucun aliment/)).toBeInTheDocument();
  });

  it('renders Import page at /import', () => {
    render(<TestApp initialEntry="/import" />);
    expect(screen.getByText('Importer un export ZIP')).toBeInTheDocument();
  });

  it('renders Repas page at /repas', () => {
    render(<TestApp initialEntry="/repas" />);
    expect(screen.getByRole('heading', { name: 'Repas' })).toBeInTheDocument();
  });

  it('renders Entrainements page at /entrainements', () => {
    render(<TestApp initialEntry="/entrainements" />);
    expect(screen.getByRole('heading', { name: 'Entraînements' })).toBeInTheDocument();
  });

  it('renders Mesures page at /mesures', () => {
    render(<TestApp initialEntry="/mesures" />);
    expect(screen.getByRole('heading', { name: 'Mesures corporelles' })).toBeInTheDocument();
  });

  it('renders Parametres page at /parametres', () => {
    render(<TestApp initialEntry="/parametres" />);
    expect(screen.getByRole('heading', { name: 'Paramètres nutritionnels' })).toBeInTheDocument();
  });
});
