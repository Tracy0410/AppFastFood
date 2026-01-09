import express from "express";
import OpenAI from "openai";

const router = express.Router();

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

router.post("/chat", async (req, res) => {
  try {
    console.log("🔥 BODY RAW:", req.body);

    const prompt = req.body.prompt;
    console.log("🧠 PROMPT:", prompt);

    if (!prompt) {
      return res.status(400).json({ answer: "Prompt rỗng" });
    }

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        { role: "user", content: prompt }
      ]
    });

    const answer = completion.choices[0].message.content;

    console.log("🤖 ANSWER:", answer);

    res.json({ answer });
  } catch (err) {
    console.error("🔥 OPENAI ERROR:", err);
    res.status(500).json({ answer: "AI lỗi, thử lại sau" });
  }
});

export default router;
