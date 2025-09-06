import { Link } from 'react-router-dom';

const NotFound = () => (
  <section className='section'>
    <div className='container'>
      <h1>Page not found</h1>
      <p>The page you’re looking for doesn’t exist.</p>
      <Link to='/' className='btn btn-primary'>
        Go home
      </Link>
    </div>
  </section>
);

export default NotFound;
