import { createContext, useCallback, useContext, useMemo, useState } from 'react';
import type { AppData, Aliment, Repas, JourRepas, Entrainement, MesuresCorporelles, ParametresNutritionnels } from '../types';
import { storage } from '../services/storage';

interface AppContextValue extends AppData {
  load: () => void;
  setAliments: (a: Aliment[]) => void;
  setRepas: (r: Repas[]) => void;
  setJoursRepas: (j: JourRepas[]) => void;
  setEntrainements: (e: Entrainement[]) => void;
  setMesures: (m: MesuresCorporelles[]) => void;
  setParametres: (p: ParametresNutritionnels | null) => void;
}

const AppContext = createContext<AppContextValue | null>(null);

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [data, setData] = useState<AppData>(() => storage.getAll());

  const load = useCallback(() => {
    setData(storage.getAll());
  }, []);

  const setAliments = useCallback((aliments: Aliment[]) => {
    setData((d) => {
      const next = { ...d, aliments };
      storage.setAliments(aliments);
      return next;
    });
  }, []);

  const setRepas = useCallback((repas: Repas[]) => {
    setData((d) => {
      const next = { ...d, repas };
      storage.setRepas(repas);
      return next;
    });
  }, []);

  const setJoursRepas = useCallback((joursRepas: JourRepas[]) => {
    setData((d) => {
      const next = { ...d, joursRepas };
      storage.setJoursRepas(joursRepas);
      return next;
    });
  }, []);

  const setEntrainements = useCallback((entrainements: Entrainement[]) => {
    setData((d) => {
      const next = { ...d, entrainements };
      storage.setEntrainements(entrainements);
      return next;
    });
  }, []);

  const setMesures = useCallback((mesures: MesuresCorporelles[]) => {
    setData((d) => {
      const next = { ...d, mesures };
      storage.setMesures(mesures);
      return next;
    });
  }, []);

  const setParametres = useCallback((parametres: ParametresNutritionnels | null) => {
    setData((d) => {
      const next = { ...d, parametres };
      storage.setParametres(parametres);
      return next;
    });
  }, []);

  const value = useMemo<AppContextValue>(
    () => ({
      ...data,
      load,
      setAliments,
      setRepas,
      setJoursRepas,
      setEntrainements,
      setMesures,
      setParametres,
    }),
    [data, load, setAliments, setRepas, setJoursRepas, setEntrainements, setMesures, setParametres]
  );

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function useApp() {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useApp must be used within AppProvider');
  return ctx;
}
