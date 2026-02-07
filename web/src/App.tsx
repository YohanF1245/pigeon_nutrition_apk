import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { AppProvider } from './context/AppContext';
import { Layout } from './components/Layout';
import { Dashboard } from './pages/Dashboard';
import { Aliments } from './pages/Aliments';
import { Repas } from './pages/Repas';
import { Entrainements } from './pages/Entrainements';
import { Mesures } from './pages/Mesures';
import { Parametres } from './pages/Parametres';
import { ImportPage } from './pages/Import';
import './App.css';

function App() {
  return (
    <AppProvider>
      <BrowserRouter basename={import.meta.env.BASE_URL}>
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
      </BrowserRouter>
    </AppProvider>
  );
}

export default App;
