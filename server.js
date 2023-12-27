// server.js
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});

const axios = require('axios');

app.get('/api/data', async (req, res) => {
  try {
    const response = await axios.get('외부 API 엔드포인트', {
      headers: {
        'Authorization': `Bearer ${process.env.API_KEY}`
      }
    });
    res.json(response.data);
  } catch (error) {
    res.status(500).send('Error');
  }
});
