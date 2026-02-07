import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { Layout } from './Layout';

function renderAt(path: string) {
  return render(
    <MemoryRouter initialEntries={[path]}>
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<span>Dashboard</span>} />
          <Route path="aliments" element={<span>Aliments</span>} />
          <Route path="import" element={<span>Import</span>} />
        </Route>
      </Routes>
    </MemoryRouter>
  );
}

describe('Layout', () => {
  it('renders title and nav', () => {
    renderAt('/');
    expect(screen.getByText('Pigeon Nutrition')).toBeInTheDocument();
    expect(screen.getByText('Tableau de bord')).toBeInTheDocument();
    expect(screen.getByText('Aliments')).toBeInTheDocument();
    expect(screen.getByText('Import')).toBeInTheDocument();
  });

  it('renders outlet for index', () => {
    renderAt('/');
    expect(screen.getByText('Dashboard')).toBeInTheDocument();
  });

  it('renders outlet for aliments', () => {
    renderAt('/aliments');
    const main = screen.getByRole('main');
    expect(main).toHaveTextContent('Aliments');
  });
});
