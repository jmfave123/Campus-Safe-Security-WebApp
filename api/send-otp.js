export default async function handler(req, res) {
  // Add CORS headers for development
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Accept');

  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { phone, message } = req.body;

  if (!phone || !message) {
    return res.status(400).json({ error: 'Phone and message are required' });
  }

  // Check if API key is configured
  if (!process.env.SEMAPHORE_API_KEY) {
    console.log('Environment variables:', Object.keys(process.env).filter(key => key.includes('SEMAPHORE')));
    return res.status(500).json({ error: 'SEMAPHORE_API_KEY not configured' });
  }
  
  console.log('API key found, length:', process.env.SEMAPHORE_API_KEY.length);

  try {
    // Call Semaphore API from server-side (no CORS!)
    const response = await fetch('https://api.semaphore.co/api/v4/otp', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        apikey: process.env.SEMAPHORE_API_KEY,
        number: phone,
        message: message,
      }),
    });

    const data = await response.json();

    if (response.ok) {
      return res.status(200).json({
        success: true,
        message: 'OTP sent successfully',
        data: data
      });
    } else {
      return res.status(response.status).json({
        success: false,
        message: data.message || 'Failed to send OTP',
        data: data
      });
    }
  } catch (error) {
    console.error('SMS API error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
}