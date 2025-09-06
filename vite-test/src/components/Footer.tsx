import './footer.css';

const Footer = () => {
  return (
    <footer className='site-footer'>
      <div className='container footer-content'>
        <p>© {new Date().getFullYear()} Acme Corp. All rights reserved.</p>
        <ul className='footer-links'>
          <li>
            <a href='#privacy'>Privacy</a>
          </li>
          <li>
            <a href='#terms'>Terms</a>
          </li>
          <li>
            <a href='#careers'>Careers</a>
          </li>
        </ul>
      </div>
    </footer>
  );
};

export default Footer;
