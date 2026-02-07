import { NavLink, Outlet } from 'react-router-dom';

const nav = [
  { to: '/', label: 'Tableau de bord', icon: '📊' },
  { to: '/aliments', label: 'Aliments', icon: '🥗' },
  { to: '/repas', label: 'Repas', icon: '🍽️' },
  { to: '/entrainements', label: 'Entraînements', icon: '💪' },
  { to: '/mesures', label: 'Mesures', icon: '📏' },
  { to: '/parametres', label: 'Paramètres', icon: '⚙️' },
];

export function Layout() {
  return (
    <div className="layout">
      <header className="header">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h1>Pigeon Nutrition</h1>
          <NavLink to="/import" style={{ color: 'rgba(255,255,255,0.9)', fontSize: '0.85rem', fontWeight: 500 }}>Import</NavLink>
        </div>
      </header>
      <main className="main">
        <Outlet />
      </main>
      <nav className="nav">
        {nav.map(({ to, label, icon }) => (
          <NavLink
            key={to}
            to={to}
            className={({ isActive }) => (isActive ? 'nav-link active' : 'nav-link')}
            end={to === '/'}
          >
            <span className="nav-icon">{icon}</span>
            <span className="nav-label">{label}</span>
          </NavLink>
        ))}
      </nav>
    </div>
  );
}
