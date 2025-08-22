import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import { initApiBaseUrl } from './services/api'   // <-- chemin corrigé

// On attend que l'API_URL soit chargée avant de lancer l'application
initApiBaseUrl().then(() => {
  createRoot(document.getElementById('root')!).render(
    <StrictMode>
      <App />
    </StrictMode>,
  )
})