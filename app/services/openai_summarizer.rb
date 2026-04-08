# frozen_string_literal: true

class OpenaiSummarizer
  SYSTEM_PROMPT = <<~PROMPT.strip
    You are a gentle, reflective writer. Given a person's raw journal entries from this week,
    write a warm, first-person narrative (2–3 paragraphs) that captures the texture of their week.
    Avoid clichés. Be specific. Sound like a human, not a recap. Do not use bullet points or headers.
    Write in plain prose only.
  PROMPT

  def initialize(entries, prompt_text: nil)
    @entries = entries
    @prompt_text = prompt_text
  end

  def call
    return nil if @entries.empty?
    return nil if ENV['OPENAI_API_KEY'].to_s.strip.empty?

    client = OpenAI::Client.new(access_token: ENV.fetch('OPENAI_API_KEY', nil))

    response = client.chat(
      parameters: {
        model: 'gpt-4o',
        temperature: 0.7,
        max_tokens: 600,
        messages: [
          { role: 'system', content: SYSTEM_PROMPT },
          { role: 'user', content: build_user_content }
        ]
      }
    )

    response.dig('choices', 0, 'message', 'content')&.strip
  rescue StandardError => e
    Rails.logger.error("[OpenaiSummarizer] Error: #{e.message}")
    nil
  end

  private

  def build_user_content
    lines = []
    lines << "Weekly prompt: #{@prompt_text}" if @prompt_text.to_s.present?
    lines << "\nMy entries this week:\n"
    lines << build_entries_text
    lines.join("\n")
  end

  def build_entries_text
    @entries.each_with_index.map do |entry, i|
      if entry.respond_to?(:prompt_text) && entry.prompt_text.present?
        "#{i + 1}. Q: #{entry.prompt_text}\nA: #{entry.content}"
      else
        "#{i + 1}. #{entry.content}"
      end
    end.join("\n")
  end
end
