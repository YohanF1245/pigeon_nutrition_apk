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

/** Zone de scan en bande horizontale (adaptée aux codes-barres EAN/UPC). */
function qrboxSizeForBarcode(viewfinderWidth: number, viewfinderHeight: number): { width: number; height: number } {
  const width = Math.floor(viewfinderWidth * 0.92);
  const height = Math.max(Math.floor(viewfinderHeight * 0.35), 80);
  return { width, height };
}

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
  const scanHandledRef = useRef(false);
  const [error, setError] = useState<string | null>(null);
  const [starting, setStarting] = useState(false);
  const [mirrorDisplay, setMirrorDisplay] = useState(true);
  const [cameras, setCameras] = useState<{ id: string; label: string }[]>([]);
  const [selectedCameraId, setSelectedCameraId] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    scanHandledRef.current = false;
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
    const cameraIdToUse = selectedCameraId;

    const timeoutId = setTimeout(() => {
      const scanner = new Html5Qrcode(containerId, {
        formatsToSupport: BARCODE_FORMATS,
        verbose: false,
      });
      scannerRef.current = scanner;

      scanner
        .start(
          cameraIdToUse,
          {
            fps: 20,
            qrbox: qrboxSizeForBarcode,
            aspectRatio: 1.333,
            disableFlip: false,
            videoConstraints: {
              deviceId: cameraIdToUse ? { exact: cameraIdToUse } : undefined,
              width: { ideal: 1280, min: 640 },
              height: { ideal: 720, min: 480 },
            },
          },
        (decodedText) => {
          if (scanHandledRef.current) return;
          const scanner = scannerRef.current;
          if (!scanner) return;
          scanHandledRef.current = true;
          scannerRef.current = null;
          scanner.stop().catch(() => {});
          const barcode = decodedText;
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
    }, 400);

    return () => {
      clearTimeout(timeoutId);
      const current = scannerRef.current;
      scannerRef.current = null;
      if (current) {
        current.stop().catch(() => {}).finally(() => setStarting(false));
      } else {
        setStarting(false);
      }
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
                minHeight: 300,
                minWidth: 320,
                width: '100%',
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
            Placez le code-barres dans le cadre blanc. Tenez le téléphone stable, à 15–20 cm du code.
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
