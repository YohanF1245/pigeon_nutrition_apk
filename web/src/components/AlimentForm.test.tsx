import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { AlimentForm } from './AlimentForm';

vi.mock('../services/openFoodFacts', () => ({
  getProductByBarcode: vi.fn(),
}));
vi.mock('./BarcodeScannerModal', () => ({
  BarcodeScannerModal: ({ open, onClose, onScan }: { open: boolean; onClose: () => void; onScan: (b: string) => void }) =>
    open ? (
      <div data-testid="scanner-modal">
        <button type="button" onClick={onClose}>Fermer scanner</button>
        <button type="button" onClick={() => onScan('3017620422003')}>Simuler scan</button>
      </div>
    ) : null,
}));

import { getProductByBarcode } from '../services/openFoodFacts';

describe('AlimentForm', () => {
  const onSave = vi.fn();
  const onCancel = vi.fn();

  beforeEach(() => {
    vi.mocked(getProductByBarcode).mockResolvedValue(null);
  });

  it('renders new aliment form', () => {
    render(<AlimentForm onSave={onSave} onCancel={onCancel} />);
    expect(screen.getByRole('heading', { name: 'Nouvel aliment' })).toBeInTheDocument();
    expect(screen.getByPlaceholderText(/Ex: Poulet/)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Enregistrer' })).toBeInTheDocument();
  });

  it('renders edit form when aliment provided', () => {
    const aliment = {
      id: 'a1',
      nom: 'Riz',
      unite: 'g' as const,
      prixUnitaire: 0,
      devise: 'EUR',
      gestionStock: false,
      quantiteStock: 0,
      quantiteAchatParDefaut: 1000,
      calories: 130,
      proteines: 2.7,
      lipides: 0.3,
      glucides: 28,
    };
    render(<AlimentForm aliment={aliment} onSave={onSave} onCancel={onCancel} />);
    expect(screen.getByRole('heading', { name: "Modifier l'aliment" })).toBeInTheDocument();
    expect(screen.getByDisplayValue('Riz')).toBeInTheDocument();
  });

  it('calls onCancel when Annuler clicked', async () => {
    const user = userEvent.setup();
    render(<AlimentForm onSave={onSave} onCancel={onCancel} />);
    await user.click(screen.getByRole('button', { name: 'Annuler' }));
    expect(onCancel).toHaveBeenCalledTimes(1);
  });

  it('submits with nom and calls onSave', async () => {
    const user = userEvent.setup();
    render(<AlimentForm onSave={onSave} onCancel={onCancel} />);
    await user.type(screen.getByPlaceholderText(/Ex: Poulet/), 'Poulet');
    await user.click(screen.getByRole('button', { name: 'Enregistrer' }));
    expect(onSave).toHaveBeenCalledWith(expect.objectContaining({ nom: 'Poulet' }));
  });

  it('does not submit when nom empty', () => {
    onSave.mockClear();
    render(<AlimentForm onSave={onSave} onCancel={onCancel} />);
    const form = screen.getByRole('button', { name: 'Enregistrer' }).closest('form');
    expect(form).toBeTruthy();
    fireEvent.submit(form!);
    expect(onSave).not.toHaveBeenCalled();
  });

  it('fetches barcode and fills form', async () => {
    vi.mocked(getProductByBarcode).mockResolvedValue({
      name: 'Nutella',
      nutriments: { calories: 225, proteines: 6, lipides: 11, glucides: 57 },
    });
    const user = userEvent.setup();
    render(<AlimentForm onSave={onSave} onCancel={onCancel} />);
    await user.type(screen.getByPlaceholderText(/Ex: 3017620422003/), '3017620422003');
    await user.click(screen.getByRole('button', { name: 'Rechercher' }));
    await screen.findByDisplayValue('Nutella');
    expect(screen.getByDisplayValue('225')).toBeInTheDocument();
  });

  it('shows error when barcode not found', async () => {
    vi.mocked(getProductByBarcode).mockResolvedValue(null);
    const user = userEvent.setup();
    render(<AlimentForm onSave={onSave} onCancel={onCancel} />);
    await user.type(screen.getByPlaceholderText(/Ex: 3017620422003/), '000');
    await user.click(screen.getByRole('button', { name: 'Rechercher' }));
    await screen.findByText(/Produit non trouvé/);
  });
});
