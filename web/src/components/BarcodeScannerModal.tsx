import { useEffect, useRef, useState } from 'react';
import { Html5Qrcode, Html5QrcodeSupportedFormats } from 'html5-qrcode';

const BARCODE_FORMATS = [
  Html5QrcodeSupportedFormats.EAN_13,
  Html5QrcodeSupportedFormats.EAN_8,
  Html5QrcodeSupportedFormats.UPC_A,
  Html5QrcodeSupportedFormats.UPC_E,
  Html5QrcodeSupportedFormats.CODE_128,
  Html5QrcodeSupportedFormats.CODE_39,
];

function preferredBackCameraId(cameras: { id: string; label: string }[]): string | null {
  const back = cameras.find((c) => /back|arrière|environment|rear/i.test(c.label));
  return back?.id ?? cameras[0]?.id ?? null;
}

interface BarcodeScannerModalProps {
  open: boolean;
  onClose: () => void;
  onScan: (barcode: string) => void;
}

export function BarcodeScannerModal({ open, onClose, onScan }: BarcodeScannerModalProps) {
  const containerId = useRef(`barcode-scanner-${Math.random().toString(36).slice(2, 9)}`).current;
  const scannerRef = useRef<Html5Qrcode | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [starting, setStarting] = useState(false);
  const [mirrorDisplay, setMirrorDisplay] = useState(true);
  const [cameras, setCameras] = useState<{ id: string; label: string }[]>([]);
  const [selectedCameraId, setSelectedCameraId] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setError(null);
    setCameras([]);
    setSelectedCameraId(null);
    Html5Qrcode.getCameras()
      .then((list) => {
        if (!list.length) {
          setError('Aucune caméra trouvée.');
          return;
        }
        const camList = list.map((c) => ({ id: c.id, label: c.label || `Caméra ${c.id.slice(0, 8)}` }));
        setCameras(camList);
        setSelectedCameraId(preferredBackCameraId(camList));
      })
      .catch(() => setError('Impossible de lister les caméras.'));
  }, [open]);

  useEffect(() => {
    if (!open || !selectedCameraId) return;

    setError(null);
    setStarting(true);
    const scanner = new Html5Qrcode(containerId, {
      formatsToSupport: BARCODE_FORMATS,
      verbose: false,
    });
    scannerRef.current = scanner;

    scanner
      .start(
        selectedCameraId,
        {
          fps: 15,
          qrbox: undefined,
          aspectRatio: 1.333,
          disableFlip: false,
          videoConstraints: {
            width: { ideal: 1280, min: 640 },
            height: { ideal: 720, min: 480 },
          },
        },
        (decodedText) => {
          const barcode = decodedText;
          scannerRef.current = null;
          onClose();
          requestAnimationFrame(() => {
            onScan(barcode);
          });
        },
        () => {}
      )
      .then(() => setStarting(false))
      .catch((err) => {
        setError(err?.message ?? 'Impossible d\'accéder à la caméra. Vérifiez les autorisations.');
        setStarting(false);
        scanner.stop().catch(() => {});
        scannerRef.current = null;
      });

    return () => {
      scannerRef.current = null;
      scanner
        .stop()
        .catch(() => {})
        .finally(() => setStarting(false));
    };
  }, [open, selectedCameraId, containerId, onScan, onClose]);

  if (!open) return null;

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 400 }}>
        <div className="modal-header">
          <h3>Scanner le code-barres</h3>
          <button type="button" className="btn icon secondary" onClick={onClose} aria-label="Fermer">
            ×
          </button>
        </div>
        <div className="modal-body">
          {error && (
            <p style={{ color: 'var(--error)', marginBottom: 12, fontSize: '0.9rem' }}>{error}</p>
          )}
          {cameras.length > 1 && (
            <label style={{ display: 'block', marginBottom: 12, fontSize: '0.9rem' }}>
              Caméra
              <select
                value={selectedCameraId ?? ''}
                onChange={(e) => setSelectedCameraId(e.target.value || null)}
                disabled={starting}
                style={{ display: 'block', width: '100%', marginTop: 4, padding: 8, borderRadius: 6, border: '1px solid var(--border)', background: 'var(--bg)', color: 'var(--text)' }}
              >
                {cameras.map((cam) => (
                  <option key={cam.id} value={cam.id}>
                    {cam.label}
                  </option>
                ))}
              </select>
            </label>
          )}
          <div
            className={mirrorDisplay ? 'barcode-scanner-mirror' : ''}
            style={{ borderRadius: 8, overflow: 'hidden', background: '#000' }}
          >
            <div
              id={containerId}
              style={{
                minHeight: 240,
                minWidth: 320,
              }}
            />
          </div>
          <label style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 12, cursor: 'pointer', fontSize: '0.9rem' }}>
            <input
              type="checkbox"
              checked={mirrorDisplay}
              onChange={(e) => setMirrorDisplay(e.target.checked)}
            />
            Inverser l&apos;affichage (si la caméra est à l&apos;envers)
          </label>
          {starting && (
            <p style={{ textAlign: 'center', marginTop: 8, color: 'var(--text-muted)' }}>
              Démarrage de la caméra…
            </p>
          )}
          <p style={{ marginTop: 12, fontSize: '0.85rem', color: 'var(--text-muted)' }}>
            Code-barres (EAN, UPC…) : placez-le face à la caméra, tout le cadre est scanné. Détection automatique.
          </p>
        </div>
        <div className="modal-footer">
          <button type="button" className="btn secondary" onClick={onClose}>
            Fermer
          </button>
        </div>
      </div>
    </div>
  );
}
