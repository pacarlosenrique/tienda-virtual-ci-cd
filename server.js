const express = require('express');
const app = express();

app.get('/', (_req, res) => {
  res.send(`
    <html>
      <head><meta charset="utf-8"><title>Tienda</title></head>
      <body style="font-family: sans-serif; margin: 40px;">
        <h1>🛒 Tienda Virtual (demo)</h1>
        <p>CI/CD con GitHub Actions → Cloud Run.</p>
        <ul>
          <li>Producto A — Q 100</li>
          <li>Producto B — Q 75</li>
          <li>Producto C — Q 50</li>
        </ul>
      </body>
    </html>
  `);
});

const port = process.env.PORT || 8080;
app.listen(port, '0.0.0.0', () => {
  console.log(`Listening on http://0.0.0.0:${port}`);
});
