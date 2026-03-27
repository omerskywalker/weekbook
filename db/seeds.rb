# frozen_string_literal: true

# Idempotent: only creates prompts that don't already exist (matched by body)

prompts = [
  # Reflection
  { category: 'reflection', body: 'What surprised you most this week?' },
  { category: 'reflection', body: 'What decision are you still thinking about?' },
  { category: 'reflection', body: 'What did this week teach you about yourself?' },
  { category: 'reflection', body: 'What would you do differently if you could rewind the week?' },
  { category: 'reflection', body: 'What conversation is still replaying in your head?' },
  { category: 'reflection', body: 'What felt harder than expected? What felt easier?' },

  # Gratitude
  { category: 'gratitude', body: 'Who made your week better, even in a small way?' },
  { category: 'gratitude', body: 'What ordinary moment are you glad you noticed?' },
  { category: 'gratitude', body: 'What did you have access to this week that you usually take for granted?' },
  { category: 'gratitude', body: 'What worked well — something you might forget to appreciate?' },
  { category: 'gratitude', body: 'What made you smile this week?' },

  # Challenge
  { category: 'challenge', body: 'What felt stuck? What got you unstuck — or kept you there?' },
  { category: 'challenge', body: 'Where did you push yourself outside your comfort zone?' },
  { category: 'challenge', body: 'What drains you right now, and what might shift that?' },
  { category: 'challenge', body: 'What is one thing you kept putting off, and what is actually stopping you?' },
  { category: 'challenge', body: 'What tension or conflict showed up this week?' },

  # Highlight
  { category: 'highlight', body: "What was the best part of your week — the moment you'd want to remember?" },
  { category: 'highlight', body: 'What did you make or ship this week, big or small?' },
  { category: 'highlight', body: 'What moment felt most like you — most aligned with who you want to be?' },
  { category: 'highlight', body: 'What did you learn this week that actually changed how you think?' },
  { category: 'highlight', body: 'If you had to describe this week in one sentence, what would it be?' },
  { category: 'highlight', body: 'What energized you this week?' }
]

prompts.each do |attrs|
  PromptTemplate.find_or_create_by!(body: attrs[:body]) do |p|
    p.category = attrs[:category]
    p.active = true
  end
end

puts "Seeded #{PromptTemplate.count} prompt templates."
