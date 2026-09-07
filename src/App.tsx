import { Navigate, Route, Routes } from 'react-router-dom'
import Splash from './pages/Splash'; import Login from './pages/Login'; import Home from './pages/Home'; import WorldMap from './pages/WorldMap'; import Mission from './pages/Mission'; import Profile from './pages/Profile'; import Supervisor from './pages/Supervisor'; import AuthGuard from './components/AuthGuard'

const P=({children}:{children:React.ReactNode})=><AuthGuard>{children}</AuthGuard>
export default function App(){return <Routes>
  <Route path="/welcome" element={<Splash/>}/><Route path="/login" element={<Login/>}/>
  <Route path="/" element={<P><Home/></P>}/><Route path="/map" element={<P><WorldMap/></P>}/>
  <Route path="/mission/:code" element={<P><Mission/></P>}/><Route path="/mission" element={<Navigate to="/map" replace/>}/>
  <Route path="/profile" element={<P><Profile/></P>}/><Route path="/supervisor" element={<P><Supervisor/></P>}/>
  <Route path="*" element={<Navigate to="/welcome" replace/>}/>
</Routes>}
