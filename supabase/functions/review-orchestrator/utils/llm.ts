export interface LLMResponse {
  content: string
  tokensUsed: number
}

export interface LLMCallInput {
  systemPrompt: string
  userPrompt: string
  model: string
}

export async function callLLM(input: LLMCallInput): Promise<LLMResponse> {
  const { systemPrompt, userPrompt, model } = input
  
  const apiKey = Deno.env.get('OPENAI_API_KEY') || Deno.env.get('ANTHROPIC_API_KEY')
  
  if (!apiKey) {
    throw new Error('LLM API key not configured. Set OPENAI_API_KEY or ANTHROPIC_API_KEY environment variable.')
  }
  
  // Determine which API to use based on model
  if (model.startsWith('gpt')) {
    return await callOpenAI(systemPrompt, userPrompt, model, apiKey)
  } else if (model.startsWith('claude')) {
    return await callAnthropic(systemPrompt, userPrompt, model, apiKey)
  } else {
    throw new Error(`Unsupported model: ${model}`)
  }
}

async function callOpenAI(
  systemPrompt: string,
  userPrompt: string,
  model: string,
  apiKey: string
): Promise<LLMResponse> {
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: model,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ],
      temperature: 0.3,
      max_tokens: 4000,
      response_format: { type: 'json_object' }
    })
  })
  
  if (!response.ok) {
    const error = await response.text()
    throw new Error(`OpenAI API error: ${response.status} - ${error}`)
  }
  
  const data = await response.json()
  const content = data.choices[0].message.content
  const tokensUsed = data.usage.total_tokens
  
  return { content, tokensUsed }
}

async function callAnthropic(
  systemPrompt: string,
  userPrompt: string,
  model: string,
  apiKey: string
): Promise<LLMResponse> {
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'Content-Type': 'application/json',
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: model,
      max_tokens: 4000,
      system: systemPrompt,
      messages: [
        { role: 'user', content: userPrompt }
      ]
    })
  })
  
  if (!response.ok) {
    const error = await response.text()
    throw new Error(`Anthropic API error: ${response.status} - ${error}`)
  }
  
  const data = await response.json()
  const content = data.content[0].text
  const tokensUsed = data.usage.input_tokens + data.usage.output_tokens
  
  return { content, tokensUsed }
}
