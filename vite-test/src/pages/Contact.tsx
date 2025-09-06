import { useState } from 'react';
import type { FormEvent } from 'react';

const Contact = () => {
  const [status, setStatus] = useState<string | null>(null);

  const onSubmit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    const name = String(form.get('name') || '').trim();
    const email = String(form.get('email') || '').trim();
    const msg = String(form.get('message') || '').trim();
    if (!name || !email || !msg) {
      setStatus('Please fill out all fields.');
      return;
    }
    setStatus('Thanks! We’ll get back to you within 1 business day.');
    e.currentTarget.reset();
  };

  return (
    <section className='section'>
      <div className='container'>
        <h1>Contact us</h1>
        <p className='lead'>Tell us about your project. We’ll follow up shortly.</p>

        <form className='card form' onSubmit={onSubmit} noValidate>
          <div className='field'>
            <label htmlFor='name'>Name</label>
            <input id='name' name='name' type='text' placeholder='Jane Doe' required />
          </div>
          <div className='field'>
            <label htmlFor='email'>Email</label>
            <input id='email' name='email' type='email' placeholder='jane@company.com' required />
          </div>
          <div className='field'>
            <label htmlFor='message'>Message</label>
            <textarea
              id='message'
              name='message'
              rows={5}
              placeholder='How can we help?'
              required
            />
          </div>
          <button className='btn btn-primary' type='submit'>
            Send message
          </button>
          {status && (
            <p role='status' className='form-status'>
              {status}
            </p>
          )}
        </form>
      </div>
    </section>
  );
};

export default Contact;
