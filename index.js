const http = require('http');
const port = process.env.PORT || 3000;
const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.statusCode = 200; res.end('ok');
  } else {
    res.end('Hello from VPS on Railway')
  }
});
server.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
