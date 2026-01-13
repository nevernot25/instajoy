# Instagram Scraper with AI Analysis

A web app that scrapes Instagram profile data and uses AI to analyze account category, gender, age range, and content themes.

## Features

- 📊 Profile information (followers, following, bio, etc.)
- 🌍 Location data (country, join date)
- 🤖 AI-powered analysis (category, gender, age, themes)
- 📝 Recent post captions
- 💾 Download results as TXT

## Deploy to Vercel

### 1. Install Vercel CLI

```bash
npm install -g vercel
```

### 2. Install Dependencies

```bash
cd vercel-app
npm install
```

### 3. Set Environment Variables

Create a `.env` file or set them in Vercel dashboard:

```
RAPIDAPI_KEY=your_rapidapi_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here
```

### 4. Deploy

```bash
vercel
```

Follow the prompts:
- Set up and deploy? **Yes**
- Which scope? Choose your account
- Link to existing project? **No**
- Project name? Press enter (use default)
- Directory? Press enter (use ./)
- Override settings? **No**

### 5. Set Environment Variables in Vercel

After first deployment:

```bash
vercel env add RAPIDAPI_KEY
vercel env add ANTHROPIC_API_KEY
```

Or set them in the Vercel dashboard:
1. Go to your project settings
2. Navigate to "Environment Variables"
3. Add both keys

### 6. Redeploy

```bash
vercel --prod
```

## Local Development

```bash
npm run dev
```

Visit `http://localhost:3000`

## API Endpoint

### POST /api/scrape

**Request:**
```json
{
  "username": "julialaurina"
}
```

**Response:**
```json
{
  "username": "julialaurina",
  "fullName": "Julia🍸| cocktail girl",
  "country": "Germany",
  "followers": 26424,
  "aiAnalysis": "Category: Lifestyle\nGender: Female\n...",
  "posts": [...]
}
```

## Tech Stack

- **Frontend:** HTML, Tailwind CSS
- **Backend:** Node.js, Vercel Serverless Functions
- **APIs:** Instagram120, Instagram Scraper Stable API, Anthropic Claude
