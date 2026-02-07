import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { BarcodeScannerModal } from './BarcodeScannerModal';

const mockStop = vi.fn().mockResolvedValue(undefined);
const mockStart = vi.fn().mockResolvedValue(undefined);

vi.mock('html5-qrcode', () => ({
  Html5Qrcode: class MockHtml5Qrcode {
    static getCameras = vi.fn().mockResolvedValue([{ id: 'cam1', label: 'Back' }]);
    start = mockStart;
    stop = mockStop;
  },
  Html5QrcodeSupportedFormats: {},
}));

describe('BarcodeScannerModal', () => {
  it('returns null when not open', () => {
    const { container } = render(
      <BarcodeScannerModal open={false} onClose={() => {}} onScan={() => {}} />
    );
    expect(container.firstChild).toBeNull();
  });

  it('renders when open and shows title', () => {
    render(<BarcodeScannerModal open onClose={() => {}} onScan={() => {}} />);
    expect(screen.getByText('Scanner le code-barres')).toBeInTheDocument();
    const fermerButtons = screen.getAllByRole('button', { name: /Fermer/ });
    expect(fermerButtons.length).toBeGreaterThanOrEqual(1);
  });

  it('calls onClose when footer Fermer clicked', async () => {
    const onClose = vi.fn();
    const user = userEvent.setup();
    render(<BarcodeScannerModal open onClose={onClose} onScan={() => {}} />);
    const buttons = screen.getAllByRole('button');
    const footerFermer = buttons.find((b) => b.textContent === 'Fermer');
    expect(footerFermer).toBeTruthy();
    await user.click(footerFermer!);
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it('toggles mirror display checkbox', async () => {
    const user = userEvent.setup();
    render(<BarcodeScannerModal open onClose={() => {}} onScan={() => {}} />);
    const checkbox = screen.getByRole('checkbox', { name: /Inverser/ });
    expect(checkbox).toBeChecked();
    await user.click(checkbox);
    expect(checkbox).not.toBeChecked();
  });
});
