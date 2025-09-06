import { Link } from 'react-router-dom';

const features = [
  {
    title: 'Strategy & Consulting',
    desc: 'We partner with you to align technology initiatives to business outcomes.',
  },
  {
    title: 'Design & UX',
    desc: 'Human-centered design that converts and delights across devices.',
  },
  {
    title: 'Cloud & DevOps',
    desc: 'Scalable, secure infrastructure with modern CI/CD and observability.',
  },
];

const Home = () => {
  return (
    <div>
      <section className='hero'>
        <div className='container hero-inner'>
          <div className='hero-copy'>
            <h1>
              Build faster. Launch smarter.
              <span className='accent'> Grow confidently.</span>
            </h1>
            <p>
              Acme Corp helps modern businesses ship great products with premium engineering and
              design services.
            </p>
            <div className='hero-cta'>
              <Link to='/contact' className='btn btn-primary'>
                Get a consultation
              </Link>
              <Link to='/services' className='btn btn-ghost'>
                Explore services
              </Link>
            </div>
          </div>
          <div className='hero-art' aria-hidden>
            <div className='glow' />
            <div className='card stat'>
              <strong>98%</strong>
              <span>Client satisfaction</span>
            </div>
            <div className='card stat'>
              <strong>25+</strong>
              <span>Active projects</span>
            </div>
          </div>
        </div>
      </section>

      <section className='section'>
        <div className='container'>
          <h2 className='section-title'>What we do</h2>
          <div className='grid-3'>
            {features.map(f => (
              <div className='card feature' key={f.title}>
                <h3>{f.title}</h3>
                <p>{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className='cta-strip'>
        <div className='container cta-content'>
          <h3>Ready to accelerate your roadmap?</h3>
          <Link to='/contact' className='btn btn-light'>
            Talk to an expert
          </Link>
        </div>
      </section>
    </div>
  );
};

export default Home;
