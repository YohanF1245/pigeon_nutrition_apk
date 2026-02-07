import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { RepasForm } from './RepasForm';

const aliments = [
  {
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
  },
  {
    id: 'a2',
    nom: 'Poulet',
    unite: 'g' as const,
    prixUnitaire: 0,
    devise: 'EUR',
    gestionStock: false,
    quantiteStock: 0,
    quantiteAchatParDefaut: 1000,
    calories: 239,
    proteines: 27,
    lipides: 14,
    glucides: 0,
  },
];

describe('RepasForm', () => {
  const onSave = vi.fn();
  const onCancel = vi.fn();

  it('renders new repas form', () => {
    render(<RepasForm aliments={aliments} onSave={onSave} onCancel={onCancel} />);
    expect(screen.getByRole('heading', { name: 'Nouveau repas' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Enregistrer' })).toBeInTheDocument();
  });

  it('renders edit form when repas provided', () => {
    const repas = { id: 'r1', nom: 'Petit-déj', aliments: [{ alimentId: 'a1', quantite: 100 }] };
    render(<RepasForm repas={repas} aliments={aliments} onSave={onSave} onCancel={onCancel} />);
    expect(screen.getByRole('heading', { name: 'Modifier le repas' })).toBeInTheDocument();
    expect(screen.getByDisplayValue('Petit-déj')).toBeInTheDocument();
  });

  it('calls onCancel when Annuler clicked', async () => {
    const user = userEvent.setup();
    render(<RepasForm aliments={aliments} onSave={onSave} onCancel={onCancel} />);
    await user.click(screen.getByRole('button', { name: 'Annuler' }));
    expect(onCancel).toHaveBeenCalledTimes(1);
  });

  it('adds line and submits', async () => {
    const user = userEvent.setup();
    render(<RepasForm aliments={aliments} onSave={onSave} onCancel={onCancel} />);
    await user.type(screen.getByPlaceholderText(/Petit-déjeuner/), 'Dejeuner');
    await user.click(screen.getByRole('button', { name: /Ajouter un ingrédient/ }));
    await user.click(screen.getByRole('button', { name: 'Enregistrer' }));
    expect(onSave).toHaveBeenCalledWith(expect.objectContaining({ nom: 'Dejeuner' }));
  });
});
