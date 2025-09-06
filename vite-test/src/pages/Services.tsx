const services = [
  { name: 'Product Discovery', details: 'User research, prototyping, and validation.' },
  { name: 'Full‑stack Development', details: 'React, Node, Python, and cloud-native delivery.' },
  { name: 'DevOps Enablement', details: 'Infrastructure as code, CI/CD, SRE practices.' },
  { name: 'Data & AI', details: 'Analytics pipelines and practical AI integrations.' },
];

const Services = () => {
  return (
    <section className='section'>
      <div className='container'>
        <h1>Services</h1>
        <div className='grid-3'>
          {services.map(s => (
            <div className='card feature' key={s.name}>
              <h3>{s.name}</h3>
              <p>{s.details}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default Services;
