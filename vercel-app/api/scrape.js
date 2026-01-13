const Anthropic = require('@anthropic-ai/sdk');
const axios = require('axios');

module.exports = async (req, res) => {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,POST');
  res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { username } = req.body;

  if (!username) {
    return res.status(400).json({ error: 'Username is required' });
  }

  try {
    const RAPIDAPI_KEY = process.env.RAPIDAPI_KEY || 'fbe3a9cfa7msh52125e1ddc815d8p1c9075jsn5a5afb01aefe';
    const ANTHROPIC_KEY = process.env.ANTHROPIC_API_KEY;

    // Fetch profile data
    const profileResponse = await axios.post(
      'https://instagram120.p.rapidapi.com/api/instagram/profile',
      { username },
      {
        headers: {
          'Content-Type': 'application/json',
          'x-rapidapi-host': 'instagram120.p.rapidapi.com',
          'x-rapidapi-key': RAPIDAPI_KEY
        }
      }
    );

    // Fetch location data
    const locationResponse = await axios.get(
      `https://instagram-scraper-stable-api.p.rapidapi.com/get_ig_user_about.php?username_or_url=${username}`,
      {
        headers: {
          'x-rapidapi-host': 'instagram-scraper-stable-api.p.rapidapi.com',
          'x-rapidapi-key': RAPIDAPI_KEY
        }
      }
    );

    // Fetch posts
    const postsResponse = await axios.post(
      'https://instagram120.p.rapidapi.com/api/instagram/posts',
      { username, maxId: '' },
      {
        headers: {
          'Content-Type': 'application/json',
          'x-rapidapi-host': 'instagram120.p.rapidapi.com',
          'x-rapidapi-key': RAPIDAPI_KEY
        }
      }
    );

    const profile = profileResponse.data.result || {};
    const location = locationResponse.data || {};
    const posts = postsResponse.data.result?.edges || [];

    // Extract captions for AI analysis
    const captions = posts.slice(0, 10).map(edge => edge.node?.caption?.text || '').filter(Boolean).join('\n\n');

    let aiAnalysis = null;

    // AI Analysis
    if (ANTHROPIC_KEY && captions) {
      try {
        const anthropic = new Anthropic({ apiKey: ANTHROPIC_KEY });

        const message = await anthropic.messages.create({
          model: 'claude-3-haiku-20240307',
          max_tokens: 500,
          messages: [{
            role: 'user',
            content: `Analyze this Instagram account and provide:
1. Account Category (e.g., Travel, Lifestyle, Fashion, Food, Fitness, Business, Tech, Home/Interior, Family, etc.)
2. Estimated Gender (Male/Female/Neutral/Unknown)
3. Estimated Age Range (e.g., 18-24, 25-34, 35-44, 45+)
4. Content Themes (3-5 main topics)

Account Info:
Name: ${profile.full_name || 'N/A'}
Bio: ${profile.biography || 'N/A'}

Recent Captions:
${captions}

Provide a brief analysis in this format:
Category: [category]
Gender: [gender]
Age Range: [age range]
Themes: [theme1, theme2, theme3]
Summary: [2-3 sentence summary]`
          }]
        });

        aiAnalysis = message.content[0].text;
      } catch (aiError) {
        console.error('AI Analysis Error:', aiError);
        aiAnalysis = 'AI analysis failed: ' + aiError.message;
      }
    }

    // Build response
    const result = {
      username: profile.username || username,
      fullName: profile.full_name || 'N/A',
      userId: profile.id || 'N/A',
      country: location.creation_country || 'N/A',
      dateJoined: location.date_joined || 'N/A',
      verifiedOn: location.verified_on || 'Not verified',
      formerUsernames: location.no_of_former_usernames || '0',
      followers: profile.edge_followed_by?.count || 0,
      following: profile.edge_follow?.count || 0,
      totalPosts: profile.edge_owner_to_timeline_media?.count || 0,
      biography: profile.biography || 'N/A',
      aiAnalysis: aiAnalysis,
      posts: posts.slice(0, 12).map(edge => ({
        date: new Date(edge.node?.taken_at * 1000).toISOString().split('T')[0],
        caption: edge.node?.caption?.text || 'No caption'
      }))
    };

    res.status(200).json(result);

  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({
      error: 'Failed to scrape Instagram data',
      details: error.message
    });
  }
};
