import './App.css'

import { BrowserRouter, Route, Routes } from 'react-router-dom'

import Layout from './components/Layout.jsx'
import Home from './pages/Home.jsx'
import ProductDetail from './pages/ProductDetail.jsx'

function App() {
  return (
    <BrowserRouter>
      <Layout>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/catalogue" element={<Home />} />
          <Route path="/produit/:id" element={<ProductDetail />} />
          <Route path="/a-propos" element={<Home />} />
          <Route path="/contact" element={<Home />} />
        </Routes>
      </Layout>
    </BrowserRouter>
  )
}

export default App
