// Vercel serverless function to proxy OTP requests
export default async function handler(req, res) {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  // Only allow POST requests
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    const { phone } = req.body;

    if (!phone) {
      res.status(400).json({ error: 'Phone number required' });
      return;
    }

    // Forward request to your working HTTP server
    const response = await fetch('http://quest4inno.mooo.com:3000/send-otp', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ phone }),
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();
    res.status(200).json(data);

  } catch (error) {
    console.error('OTP proxy error:', error);
    res.status(500).json({ 
      error: 'Failed to send OTP',
      details: error.message 
    });
  }
}
