import { Outlet } from 'react-router-dom';
import Navbar from './Navbar';
import Footer from './Footer';

const MainLayout = () => {
  return (
    <div className='app-root'>
  <a className='skip-link' href='#main'>Skip to content</a>
      <Navbar />
  <main id='main' className='site-main'>
        <Outlet />
      </main>
      <Footer />
    </div>
  );
};

export default MainLayout;
