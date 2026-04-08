# frozen_string_literal: true

# Idempotent: only creates prompts that don't already exist (matched by body).
# After upserting the new pool, any prompt whose body is no longer in the list
# is marked inactive so it won't be dispatched.

new_prompts = [
  # Joy — things that made you happy, laugh, smile
  { category: 'joy', body: "what's something that made you laugh today?" },
  { category: 'joy', body: 'what was your fav meal this week?' },
  { category: 'joy', body: "what's a small thing that made today feel good?" },
  { category: 'joy', body: "what made you smile when you weren't expecting to?" },
  { category: 'joy', body: 'what was the most fun moment of your week?' },
  { category: 'joy', body: 'what song, show, or book brought you joy lately?' },
  { category: 'joy', body: 'who made you laugh this week?' },
  { category: 'joy', body: "what's something silly or weird that happened this week?" },
  { category: 'joy', body: "what's something you did just for fun this week?" },

  # Gratitude — appreciation, noticing good things
  { category: 'gratitude', body: "what's something small you're grateful for today?" },
  { category: 'gratitude', body: 'who made your day a little easier this week?' },
  { category: 'gratitude', body: "what's something you usually take for granted that stood out this week?" },
  { category: 'gratitude', body: 'what worked out better than expected this week?' },
  { category: 'gratitude', body: "what's a comfort in your life you're really glad you have?" },
  { category: 'gratitude', body: "what's a kind thing someone did for you recently?" },
  { category: 'gratitude', body: "what's something at home that made your week nicer?" },
  { category: 'gratitude', body: 'what moment from this week do you want to hold on to?' },
  { category: 'gratitude', body: "what's one thing about today you're actually glad happened?" },

  # Connection — relationships, showing up for people
  { category: 'connection', body: 'how did you show up for a loved one this week?' },
  { category: 'connection', body: "what's something nice you did for someone else?" },
  { category: 'connection', body: 'who did you spend time with this week and how did it feel?' },
  { category: 'connection', body: "did you reach out to anyone you hadn't talked to in a while?" },
  { category: 'connection', body: "what's a conversation from this week you're glad you had?" },
  { category: 'connection', body: "who do you wish you'd checked in on this week?" },
  { category: 'connection', body: 'did anyone surprise you with how much they cared?' },
  { category: 'connection', body: "what's something you did that probably meant more to someone than you realise?" },
  { category: 'connection', body: 'who are you feeling especially close to right now?' },

  # Self — self-care, personal growth, how you treated yourself
  { category: 'self', body: "what's something nice you did for yourself this week?" },
  { category: 'self', body: 'how did you take care of your body today?' },
  { category: 'self', body: "what's something you're proud of yourself for this week?" },
  { category: 'self', body: 'did you give yourself a break when you needed one?' },
  { category: 'self', body: "what's one thing you said yes to that was good for you?" },
  { category: 'self', body: "what's one thing you said no to that was good for you?" },
  { category: 'self', body: "what's something you're getting better at, even slowly?" },
  { category: 'self', body: 'how did you handle a tough moment this week?' },
  { category: 'self', body: 'what did you do this week that felt like the truest version of you?' },

  # Memory — things to remember, favourite moments
  { category: 'memory', body: "what's something you'd like to remember about this week?" },
  { category: 'memory', body: "what's a moment from today worth writing down?" },
  { category: 'memory', body: 'if you could freeze one moment from this week, what would it be?' },
  { category: 'memory', body: "what's something that happened this week that you don't want to forget?" },
  { category: 'memory', body: 'what image from this week keeps coming back to you?' },
  { category: 'memory', body: "what's something funny you want to remember?" },
  { category: 'memory', body: "what's a detail from this week — a smell, a sound, a feeling — you want to hold on to?" },
  { category: 'memory', body: "what's a first you had this week, big or tiny?" },
  { category: 'memory', body: "what's something that happened this week you'll still remember in a year?" },

  # Anticipation — looking forward, excitement, hope
  { category: 'anticipation', body: 'what made you excited this week?' },
  { category: 'anticipation', body: "what's something you're looking forward to?" },
  { category: 'anticipation', body: "what's a plan you're quietly excited about?" },
  { category: 'anticipation', body: "what's something coming up that you can't stop thinking about?" },
  { category: 'anticipation', body: "what's a small thing you're hoping for this week?" },
  { category: 'anticipation', body: 'what would make next week feel great?' },
  { category: 'anticipation', body: "what's a dream or goal that feels a little more possible lately?" },
  { category: 'anticipation', body: "what are you in the middle of that you're excited to finish?" },
  { category: 'anticipation', body: "what's something you've been wanting to try?" }
]

new_prompts.each do |attrs|
  PromptTemplate.find_or_create_by!(body: attrs[:body]) do |t|
    t.category = attrs[:category]
    t.active   = true
  end
end

# Deactivate any prompts from the old pool that are no longer in the new list
new_bodies = new_prompts.pluck(:body)
deactivated = PromptTemplate.where.not(body: new_bodies).update_all(active: false) # rubocop:disable Rails/SkipsModelValidations

Rails.logger.debug { "Seeded #{new_prompts.size} prompt templates (#{deactivated} old prompts deactivated)." }
