require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Initialize Gemini AI
const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY_1 || process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

// RAG Endpoint for AI Recommendations
app.post('/ai/recommendations', async (req, res) => {
  try {
    const { vibeText, nearbyPlaces } = req.body;

    if (!nearbyPlaces || !Array.isArray(nearbyPlaces) || nearbyPlaces.length === 0) {
      return res.status(400).json({ error: "No nearby places provided for context." });
    }

    console.log(`Received request. Vibe: "${vibeText}", Nearby Places Count: ${nearbyPlaces.length}`);

    // Construct the RAG Context (System Instruction equivalent)
    const contextStr = JSON.stringify(nearbyPlaces, null, 2);
    
    const prompt = `
You are an expert travel guide AI for Sri Lanka.
A user is asking for recommendations based on their vibe/preference: "${vibeText}".

Here is the JSON data of places available near them (This is your ONLY knowledge base for this request):
${contextStr}

Task:
1. Analyze the user's vibe and match it against the provided JSON places.
2. Select the top 3 best matching places from the provided JSON. 
3. You must ONLY recommend places that exist in the provided JSON data.
4. Return the result STRICTLY as a JSON array of objects. 
5. Each object must have exact two keys: "id" (the place id) and "reason" (a 1-2 sentence compelling reason why it matches their vibe).
6. Do not include markdown formatting like \`\`\`json, just return the raw JSON array.

Example Output format:
[
  {
    "id": "pl_123",
    "reason": "This place perfectly matches your vibe because..."
  }
]
`;

    // Call Gemini with the Prompt (which includes the RAG context)
    const result = await model.generateContent(prompt);
    const response = await result.response;
    let aiText = response.text().trim();
    
    // Clean up potential markdown formatting from Gemini
    if (aiText.startsWith('```json')) {
      aiText = aiText.substring(7, aiText.length - 3).trim();
    } else if (aiText.startsWith('```')) {
      aiText = aiText.substring(3, aiText.length - 3).trim();
    }

    const recommendations = JSON.parse(aiText);
    res.json(recommendations);

  } catch (error) {
    console.error("AI Error:", error);
    res.status(500).json({ error: "Failed to generate AI recommendations", details: error.message });
  }
});

app.listen(port, () => {
  console.log(`TripMe AI Backend (RAG Server) is running on http://localhost:${port}`);
});
