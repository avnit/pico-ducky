---
name: explain-code
description: >
  Explains code with visual ASCII diagrams and real-world analogies. Use when
  explaining how code works, teaching a codebase, or when user asks "how does
  this work?", "walk me through", "explain this", or "what does this do?".
---

# Explain Code

When explaining code, always include all four of these:

## 1. Real-World Analogy
Compare the code to something from everyday life. Make it memorable.
Example: "A middleware stack is like a series of security checkpoints at an
airport — each one can inspect your bag, add a stamp, or turn you away."

## 2. ASCII Diagram
Draw the flow, structure, or relationships visually:
```
Request → [AuthMiddleware] → [RateLimiter] → [Handler] → Response
               ↓ fail              ↓ fail
             401                  429
```

## 3. Step-by-Step Walkthrough
Narrate exactly what happens, in execution order. Reference actual line
numbers or function names from the code. Use plain English.

## 4. The Gotcha
Identify one thing that commonly trips people up, a non-obvious
behavior, or a footgun in this code. Label it clearly:

> ⚠️ **Gotcha**: ...

## Style
- Conversational, not academic
- For complex concepts, use multiple analogies
- If the code has a bug or smell, mention it briefly at the end
