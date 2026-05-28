---
name: anti-ai-tells
description: Strip the AI-chatbot fingerprint out of written content. Use whenever drafting, editing, or reviewing prose that needs to read as human-written — articles, blog posts, essays, reports, Wikipedia edits, marketing copy, emails, fiction, anything where "this was clearly written by ChatGPT" would be a problem. Also use as a self-review pass after generating any long-form text, even if the user didn't explicitly ask for it to sound human. Based on Wikipedia's "Signs of AI writing" field guide (WP:AISIGNS), the most comprehensive empirical catalog of LLM writing tells in existence.
---

# Anti-AI-Tells

A field guide for producing written content that doesn't read as machine-generated. Distilled from [Wikipedia:Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing), which catalogues patterns that WikiProject AI Cleanup volunteers identified across thousands of flagged AI-generated edits.

## When to use this skill

Use during two distinct phases:

**While drafting.** Hold the patterns below in mind as you write so you don't produce them in the first place. This is more effective than catching them after.

**As a final review pass.** Before delivering any long-form prose, walk the checklist at the bottom and revise anything that trips it. Treat the checklist as a real gate, not a formality — if a piece reads as AI-generated, the writing has failed regardless of whether the facts are right.

## What this skill is not

It is not a ban on em-dashes, lists, or any specific word. Real human writers use all of these. The signal isn't any single feature — it's the combination, the density, and the predictability. A piece with one em-dash is fine. A piece with em-dashes in every paragraph used where commas would do reads as AI.

It is also not about hiding AI use deceptively. It is about producing prose that has the texture of considered human writing — specific, uneven, opinionated, sometimes spiky — rather than the smoothed-out chatbot mean.

---

## The patterns

Organized by category, roughly in order of "things readers notice most" first. Each pattern has the tell, why it's a tell, and the fix.

### 1. Puffery and emphasis on importance

**The single biggest AI tell.** LLMs trend toward describing everything as significant, notable, important, or impactful. They reach for flattering generic adjectives because those are statistically common in their training data.

Words and phrases to be deeply suspicious of when you've written them:
- "rich cultural heritage", "rich tapestry", "rich history"
- "stands as a testament to", "serves as a testament to"
- "plays a vital/significant/crucial/pivotal role"
- "leaves a lasting impact", "leaves an indelible mark", "enduring legacy"
- "a profound/profoundly", "deeply rooted"
- "captivating", "compelling", "fascinating", "intriguing" (when applied as filler praise)
- "renowned", "celebrated", "acclaimed", "esteemed", "distinguished"
- "breathtaking", "stunning", "remarkable", "extraordinary"
- "underscores", "highlights the importance of", "emphasizes"
- "in the ever-evolving landscape of", "in today's [adjective] world"
- "navigating the complexities of"
- "the symbolism of", "symbolizes", "represents more than just"

**Fix:** Cut the praise word entirely or replace it with a concrete specific. "A renowned 19th-century chemist" → "A 19th-century chemist whose textbook was the standard at French universities for forty years." Specifics beat adjectives.

**Watch especially for:** declaring something important without showing why. If you wrote "X plays a significant role in Y," ask what role specifically, and write that instead.

### 2. The rule of three

LLMs love three-item lists. "Bold, innovative, and effective." "Smart, creative, and driven." "He was a writer, a thinker, and a leader."

The pattern is so consistent that an unexplained triplet is a tell on its own. Human writers use triplets sometimes, but not in every paragraph and rarely with such suspiciously balanced parallelism.

**Fix:** If you wrote a triplet, ask whether you actually mean three things or whether you reflexively reached for three. Cut to two, expand to a real list of five, or replace with one precise thing. "Bold, innovative, and effective" → "effective in ways no one had tried" (or just "effective").

### 3. Negative parallelism: "not only X, but also Y"

"This was not only a victory, but also a turning point." "The book is not just a memoir, but a meditation on grief."

This construction is grammatical and sometimes appropriate, but LLMs reach for it constantly because it lets them inflate a single claim into two without committing to either. Watch also for: "more than just", "far more than", "not merely".

**Fix:** Pick the stronger half and say that. "Not just a memoir but a meditation on grief" → "A meditation on grief, structured as memoir."

### 4. Editorializing and vague attribution

LLMs insert opinions and "some critics argue" framing into descriptive text. They round corners off and add a layer of evaluative cushioning.

Tells:
- "Some critics argue", "many believe", "experts say", "scholars note"
- "It is widely considered", "is often regarded as", "has been described as"
- "It is worth noting that", "it should be noted", "notably"
- Trailing -ing analysis: "...improving convenience", "...highlighting the issue", "...marking a turning point"

These constructions assert importance, opinion, or analysis without sourcing it. The trailing -ing clause in particular is a Claude/ChatGPT signature — a sentence concludes its factual content, then attaches a tail that interprets the fact for the reader.

**Fix:** Either cite who specifically said it (with a real source) or cut the attribution entirely. If you don't have a source for "many critics consider this her best work," you don't have the claim. For -ing tails: most can be deleted without losing information. "The bill passed unanimously, marking a rare moment of bipartisan agreement" → "The bill passed unanimously."

### 5. Section-level formulaic structure

LLMs gravitate toward predictable section structures, especially when asked to write about a topic at length:
- "Background" → "Overview" → "Key Features" → "Challenges" → "Future Prospects" → "Conclusion"
- Articles that end with a "Legacy" or "Impact" section regardless of whether the subject has any
- "Pros and Cons" sections that didn't need to exist
- A summary/conclusion paragraph that restates what was just said

Real writing has the structure the subject demands. A piece about an obscure 1970s lawsuit doesn't need a "Future Prospects" section.

**Fix:** Build the outline from the content, not from a template. If a section header could appear unchanged on a thousand other articles, ask whether it's earned.

### 6. Conclusion phrases that don't belong

"In summary,..." "Overall,..." "In conclusion,..." "To wrap up,..." "It is clear that..." "Ultimately,..."

These work in essays where a conclusion is structurally expected. They are tells in Wikipedia articles, news writing, blog posts, fiction, and most other contexts — and even in essays they're often filler.

**Fix:** Just delete the transition. The final paragraph being the final paragraph is enough signal.

### 7. Em-dash overuse

The em-dash issue is widely discussed and somewhat overhyped — many humans love em-dashes. The actual tell is *frequency and placement*: LLMs use em-dashes more than humans of the same genre, and use them in slots where a comma, colon, parenthetical, or period would normally appear.

**Fix:** Don't ban em-dashes. Do count them. If a 500-word piece has more than two or three, replace most with commas, periods, or parentheses. Reserve em-dashes for actual interruptions and dramatic shifts.

### 8. Anaphora and short-line breaks

A pattern especially associated with Claude: a sequence of short sentences, often starting with the same word, sometimes separated by paragraph breaks for emphasis.

> It was real.
>
> It was urgent.
>
> It was happening now.

This is fine sparingly in stylized writing. It is a tell when it shows up in factual prose or accumulates across a long response.

**Fix:** Combine into normal sentences. Use the pattern only when the rhetorical force is genuinely earned.

### 9. Excessive formatting

LLM chat outputs are trained heavily on Markdown, and that habit leaks into prose:
- Bold every key term in a paragraph
- Bullet lists where prose would read better
- Headers for short sections that don't need them
- Title Case Headings For Everything
- Bullets that are sentence fragments rather than complete thoughts

The default Wikipedia article, news article, or blog post uses paragraphs, not bullets. Bullets earn their place when the content is genuinely list-shaped (steps, options, parallel items). They don't earn it when prose is being chopped up to look organized.

**Fix:** Convert most bullets to prose. Reserve bold for genuine emphasis (rare). Use sentence case for headings unless the publication style demands otherwise.

### 10. Curly quotes and other Markdown artifacts

Chatbot interfaces render Markdown, so curly quotes ("smart quotes"), em-dashes, and similar typography appear as default output. Pasted into a context expecting straight quotes (code, raw text, some CMSes), they're a giveaway.

**Fix:** When the destination is a context that uses straight quotes by default, convert them. Watch also for: orphan Markdown syntax (`**bold**` appearing literally), stray `#` characters, and bullets rendered as `* ` in plain text.

### 11. Knowledge-cutoff and meta-disclaimers

"As of my last knowledge update..." "I cannot verify current information..." "As an AI, I..." These should never appear in delivered content. They are signs of the chatbot speaking to the user rather than the writing existing on its own terms.

Related tells in non-meta contexts:
- "Certainly!" "Of course!" "I'd be happy to..." at the start of a piece
- "I hope this helps!" "Let me know if you have any questions!" at the end
- Refusal language embedded in content: "I cannot provide..." appearing mid-paragraph

**Fix:** Strip all of these. Written content should not address a reader as if from a chat session.

### 12. Sourcing tics

When LLMs invent sources or pad citations, certain patterns appear:
- Every claim cited, even uncontroversial ones ("Paris is the capital of France [1]")
- Heavy in-text source emphasis: "According to a 2024 study by Smith et al. published in Nature..."
- Citations that look real but resolve to nothing, or to wrong articles
- Vague gestures: "various studies have shown", "research suggests"

**Fix:** Cite at the granularity the genre expects. For Wikipedia, that's per-claim for anything non-obvious. For an essay, sparingly. And verify the sources exist — if you can't find the citation, you don't have the citation.

### 13. The smoothed-out mean

This is the meta-pattern under most of the above. LLMs are trained to produce the statistically average response, which sands off the specific, the odd, the contrary, the personal. The result reads like a competent freshman essay on any topic — grammatical, organized, and saying nothing surprising.

Signs you've slipped into the mean:
- Every sentence makes sense but no sentence is surprising
- The piece could be about a different subject with names swapped
- There's no detail a non-expert wouldn't already know
- There's no opinion that would offend a hypothetical reader
- The voice could be anyone's

**Fix:** Add at least one specific that only this subject has. Add at least one claim that someone could disagree with. Cut the parts that any article on this topic would say.

---

## The review checklist

After drafting, read through once with this checklist active. Mark the piece against each item.

1. **Puffery scan.** Search the draft for: testament, vital role, rich heritage, profound, captivating, renowned, breathtaking, underscores, ever-evolving. Cut or replace each one.

2. **Triplet count.** How many three-item parallel lists are there? More than one or two in a short piece is too many.

3. **"Not only" search.** Find every instance. Keep at most one if it's genuinely doing work.

4. **Attribution audit.** Find every "some critics", "many believe", "experts say", "it is considered". Either source it specifically or cut it.

5. **-ing tail audit.** Find every sentence ending in a comma + -ing clause that adds interpretation. Delete the tails unless they add real information.

6. **Conclusion phrases.** Search: "In summary", "Overall", "In conclusion", "Ultimately", "It is clear that". Usually delete.

7. **Em-dash count.** Count them. In a 500-word piece, two or three max. Replace excess with commas, periods, or parentheses.

8. **Structure check.** Are section headers earned by the content, or template-shaped? Does it end with a summary it doesn't need?

9. **Formatting check.** Is anything bolded that doesn't need to be? Are there bullets that should be prose? Headers that should be inline emphasis?

10. **Meta-language scan.** Any "Certainly!", "I hope this helps", "As an AI", knowledge-cutoff caveats, or chatbot pleasantries? Strip all.

11. **Specificity check.** Pick three sentences at random. Could each one appear in an article about a different subject with names swapped? If yes, add specifics that only fit this subject.

12. **Voice check.** Does any of this read as opinionated, particular, or surprising? Or is it all the consensus average? If it's all average, add at least one sharp specific claim.

---

## Caveats

These are tells, not crimes. A piece written by a careful human about a subject they love will sometimes do these things. The skill is meant to push back against AI defaults, not to enforce a single style.

Genre matters. Marketing copy and Wikipedia have different defaults from fiction. The puffery list is more dangerous in encyclopedic writing than in a movie trailer. Adjust accordingly.

Voice matters. If the user has asked for an ornate, lyrical style, em-dashes and emphatic adjectives may be appropriate. The checklist is for the default case of writing that should read as competent neutral human prose.

When uncertain, prefer the more specific, more concrete, less smoothed version. AI mistakes trend toward the generic, so erring toward the particular is usually the right correction.
