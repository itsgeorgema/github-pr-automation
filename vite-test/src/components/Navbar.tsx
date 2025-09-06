import { Link, NavLink } from 'react-router-dom';
import './navbar.css';
import { useState } from 'react';

const Navbar = () => {
  const [open, setOpen] = useState(false);
  return (
    <header className='navbar'>
      <div className='container nav-content'>
        <Link to='/' className='brand'>
          <span className='brand-mark'>◆</span> Acme Corp
        </Link>
        <button
          className='nav-toggle'
          aria-label='Toggle navigation'
          aria-expanded={open}
          onClick={() => setOpen(o => !o)}
        >
          ☰
        </button>
        <nav className={`nav-links ${open ? 'open' : ''}`} onClick={() => setOpen(false)}>
          <NavLink to='/' end>
            Home
          </NavLink>
          <NavLink to='/about'>About</NavLink>
          <NavLink to='/services'>Services</NavLink>
          <NavLink to='/contact'>Contact</NavLink>
        </nav>
      </div>
    </header>
  );
};

export default Navbar;
