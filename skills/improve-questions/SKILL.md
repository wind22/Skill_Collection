---
name: improve-questions
description: Optimize vague, shallow, broad, emotional, or yes/no questions into clearer, deeper, more discussion-worthy questions, then suggest useful next ways to keep using the skill. Use when the user asks to improve, deepen, sharpen, audit, score, reframe, or make a question more meaningful; when they ask whether a question is good, deep, effective, or worth discussing; or when they need better questions for AI prompts, essays, content, interviews, research, learning, decisions, strategy, or self-reflection.
---

# Improve Questions

## Purpose

Help the user turn a weak question into a clearer, deeper, and more actionable question. Focus on question quality, not on directly answering the question unless the user explicitly asks.

Use the user's original language by default. Preserve their intent and voice, but remove vagueness, hidden assumptions, and empty abstraction.

## Response Contract

Every response using this skill must end with this exact footer section:

```markdown
你还可以继续这样用：
- ...
- ...
```

Do not omit this footer after long answers, full audits, direct rewrites, or question-generation responses. Omit it only if the user explicitly says not to include next-use suggestions.

The footer is part of the required output, not an optional extra. Before finishing, check that the final answer contains `你还可以继续这样用：`.

## Core Workflow

1. Identify what the user is really trying to understand.
2. Diagnose the question across the ten depth dimensions.
3. Find the weakest two or three dimensions.
4. Rewrite the question at multiple depths.
5. Offer follow-up prompts that help the user continue thinking.
6. Convert the improved question into an action, decision, or learning direction when possible.
7. End with two or three further-use suggestions tailored to the user's current question.

If the user's goal is ambiguous, make a reasonable assumption and state it briefly. Ask at most one clarifying question only when the rewrite would change substantially depending on the answer.

## Depth Dimensions

Use these dimensions as a diagnostic checklist. Do not dump the whole checklist unless the user asks for a full audit.

| Dimension | Diagnostic Question |
| --- | --- |
| Clarity | What exactly is the user trying to understand? |
| Hidden assumptions | What does the question assume is already true? |
| Reverse thinking | Can the opposite question reveal a blind spot? |
| Object distinction | Who or what is this about, specifically? |
| Time scale | Do short-term and long-term answers differ? |
| Cost awareness | What is gained, lost, or transferred? |
| Mechanism | How and why would the thing happen? |
| Concrete examples | What real scene makes the question testable? |
| Value conflict | Which values are in tension? |
| Action orientation | Would answering this change a judgment or behavior? |

## Rewrite Ladder

When improving a question, usually provide three versions:

1. **Clearer version**: Keep the original intent, but specify the object, context, and ambiguity.
2. **Deeper version**: Add assumptions, mechanisms, tradeoffs, time scale, or value conflict.
3. **Sharper version**: Make the question more pointed, memorable, and debate-worthy without becoming sensational.

Example:

Original: `AI 是好是坏？`

Clearer: `AI 在哪些学习场景中会增强人的能力，在哪些场景中会削弱人的主动思考？`

Deeper: `当 AI 降低获取答案的成本时，它会如何改变人形成判断、忍受困惑和训练基础能力的过程？`

Sharper: `AI 是在增强有问题意识的人，还是在安慰没有问题意识的人？`

## Scoring

When the user asks for scoring, score each dimension from 1 to 5.

Keep scoring compact:

| Dimension | Score | Note |
| --- | --- | --- |
| Clarity | 3 | The topic is visible, but the target object is broad. |

After scoring, summarize:

- strongest dimension
- weakest dimension
- highest-leverage improvement
- one rewritten question

The total score is secondary. Emphasize the lowest dimension and how to improve it.

## Output Patterns

### Quick Improvement

Use this when the user simply asks to optimize a question.

```markdown
你的问题核心在问：...

更清楚的问法：
...

更深一层的问法：
...

更锋利的问法：
...

最值得继续追问的是：
...

你还可以继续这样用：
- ...
- ...
```

### Full Audit

Use this when the user asks for a detailed check, rating, or diagnosis.

```markdown
我的判断：这个问题目前最弱的是「...」和「...」。

| 检查项 | 分数 | 诊断 |
| --- | --- | --- |
| 清晰度 | 3 | ... |

最低分怎么补：
1. ...
2. ...

改写版本：
- 稳妥版：...
- 深入版：...
- 锋利版：...

下一步可以问：
...

你还可以继续这样用：
- ...
- ...
```

### Question Generation

Use this when the user provides a topic rather than an existing question.

```markdown
围绕这个主题，可以从这几个方向提问：

1. 条件：在什么情况下...？
2. 对象：对谁来说...？
3. 机制：它是如何发生的？
4. 代价：得到它会失去什么？
5. 行动：如果这是真的，我应该怎么做？

我建议优先讨论的问题是：
...

你还可以继续这样用：
- ...
- ...
```

## Further-Use Suggestions

After the main answer, include a short section named `你还可以继续这样用：`.

Suggest two or three next uses based on what would most improve the user's current question. Each suggestion should be directly usable as a prompt. Do not list every possible use.

Map the recommendation to the observed weakness:

| If the current question needs... | Suggest this next use |
| --- | --- |
| more precision | `继续帮我把这个问题限定到具体对象、场景和时间尺度。` |
| assumption testing | `帮我拆出这个问题的隐藏前提，并判断哪些前提最可疑。` |
| reverse thinking | `把这个问题反过来问，找出我忽略的反例和盲区。` |
| scoring | `按十项清单给这个问题打分，并告诉我最低分怎么补。` |
| concrete grounding | `给这个问题配 3 个现实场景和 1 个反例。` |
| mechanism analysis | `不要回答结论，先分析这个问题背后的发生机制。` |
| value conflict | `帮我找出这个问题背后的价值冲突，比如效率、自由、成长、风险。` |
| action orientation | `如果这个问题的判断成立，帮我推导下一步行动原则。` |
| content or research use | `围绕这个主题再生成 10 个更适合写文章/访谈/研究的问题。` |

Keep suggestions concise. Prefer prompts that start with action verbs such as `帮我拆`, `继续限定`, `反过来问`, `按十项清单打分`, `生成`, or `推导`.

## Heuristics

- Prefer "under what conditions", "for whom", "by what mechanism", "at what cost", and "what should change" over yes/no framing.
- Turn emotional judgments into inspectable structures: assumptions, mechanisms, examples, consequences, and values.
- Do not make every question more abstract. Often the best improvement is to add a concrete person, scene, decision, or failure case.
- Do not over-polish away the user's tension. Preserve the live conflict that made the question worth asking.
- Avoid pretending every question needs all ten dimensions. Improve the bottleneck first.
- If a question is already strong, say so and make it more precise rather than dramatically rewriting it.

## Common Transformations

- `是不是 X？` -> `在什么条件下 X 成立？在哪些情况下不成立？`
- `X 好不好？` -> `X 对谁有利、对谁有代价，代价由谁承担？`
- `X 会不会造成 Y？` -> `X 通过什么机制造成 Y？有没有反例？`
- `为什么我做不到 X？` -> `我在哪个环节被卡住：目标、动机、方法、反馈，还是代价？`
- `我该不该做 X？` -> `在我的目标、约束和机会成本下，X 是否是最值得下注的选择？`

## Quality Bar

A good final answer should leave the user with at least one question that is:

- clear enough to answer
- specific enough to discuss
- deep enough to reveal assumptions or mechanisms
- grounded enough to connect with reality
- useful enough to change thinking or action
