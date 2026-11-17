for (const form of document.querySelectorAll('form[data-endpoint]')) {
  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    const output = form.querySelector('output');
    const values = Object.fromEntries(new FormData(form));
    output.textContent = 'Working...';

    try {
      const response = await fetch(form.dataset.endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(values),
      });
      const result = await response.json();
      if (!response.ok) {
        throw new Error(result.error);
      }
      output.textContent = result.result;
    } catch (error) {
      output.textContent = `Error: ${error.message}`;
    }
  });
}
