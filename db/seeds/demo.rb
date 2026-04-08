# frozen_string_literal: true

raise 'Demo seeds cannot run in production!' if Rails.env.production?

def make_entry(user, date, prompt_text, content)
  Entry.find_or_create_by!(user: user, week_start_date: date.beginning_of_week(:monday), content: content) do |e|
    e.prompt_text = prompt_text
  end
end

# ---------------------------------------------------------------------------
# Users
# ---------------------------------------------------------------------------
demo_user = User.find_or_create_by!(email: 'demo@weekbook.dev') do |u|
  u.password = 'password'
  u.username = 'demo'
  u.display_name = 'Alex Rivera'
  u.bio = 'Just trying to notice the good stuff.'
end

follower1 = User.find_or_create_by!(email: 'jamie@weekbook.dev') do |u|
  u.password = 'password'
  u.username = 'jamie'
  u.display_name = 'Jamie Chen'
end

Follow.find_or_create_by!(follower: follower1, followed: demo_user)
Follow.find_or_create_by!(follower: demo_user, followed: follower1)

# ---------------------------------------------------------------------------
# Week 1 — 3 weeks ago: entries + published digest
# ---------------------------------------------------------------------------
week1_start = 3.weeks.ago.to_date.beginning_of_week(:monday)

make_entry(demo_user, week1_start, "what's something that made you laugh today?",
           "My coworker tried to explain a meme to someone who'd never seen it and somehow made it less funny with every sentence. I was crying laughing.")
make_entry(demo_user, week1_start, "what's something nice you did for someone else?",
           "Sent my friend a voice note just to tell her she's been a good friend lately. She called me immediately and we talked for an hour.")
make_entry(demo_user, week1_start, 'what was your fav meal this week?',
           'Made shakshuka on Sunday morning with the last of the tomatoes from the farmers market. Ate it slow with good coffee. Could have stayed at that table all day.')
make_entry(demo_user, week1_start, 'what made you excited this week?',
           "Got early access to a project I've been waiting months to see. Stayed up way too late going through it.")
make_entry(demo_user, week1_start, 'how did you show up for a loved one in your life?',
           "My brother called stressed about work stuff. I didn't try to fix it, just listened. He said it helped.")
make_entry(demo_user, week1_start, "what's something you'd like to remember about this week?",
           'The light on Tuesday evening around 6pm. Just walked outside and it was golden and everything looked cinematic for about 10 minutes.')

WeeklyDigest.find_or_create_by!(user: demo_user, week_start_date: week1_start) do |d|
  d.week_number = week1_start.cweek
  d.year = week1_start.year
  d.summary_line = 'A week of small moments — a golden hour, a long catch-up call, and shakshuka eaten slowly.'
  d.content = "This week had a quiet rhythm to it. There was a meal that deserved more attention than most — shakshuka made with the last good tomatoes of the season, eaten slowly on a Sunday morning with nowhere to be. That kind of morning sets a tone.\n\nI found myself showing up for people in ways that didn't require much, but seemed to matter anyway. A voice note sent on a whim turned into an hour-long call. A phone call with my brother where I just listened instead of problem-solving. Small gestures, but they landed.\n\nThe week had its bright spots too — that golden light on Tuesday evening that turned everything cinematic for a few minutes, a meme that somehow got less funny the more it was explained, and early access to something I'd been waiting on for months.\n\nMostly this was a week of noticing. The good stuff was there — it just needed a little attention."
  d.status = 'published'
end

# ---------------------------------------------------------------------------
# Week 2 — 2 weeks ago: entries + published digest
# ---------------------------------------------------------------------------
week2_start = 2.weeks.ago.to_date.beginning_of_week(:monday)

make_entry(demo_user, week2_start, "what's something that made you smile today?",
           'A dog on the subway sat perfectly still and looked deeply unbothered by everything. Goals honestly.')
make_entry(demo_user, week2_start, "what's something nice you did for yourself?",
           "Took a real lunch break for the first time in weeks. Sat outside, didn't look at my phone. It felt almost rebellious.")
make_entry(demo_user, week2_start, "what's something you're looking forward to?",
           "Visiting my parents next month. I always think I'll feel neutral about it and then I get there and remember how good it feels to just be home.")
make_entry(demo_user, week2_start, 'what made you excited this week?',
           'A random idea I had in the shower actually turned out to be viable when I sketched it out. That almost never happens.')
make_entry(demo_user, week2_start, "what's something you'd like to remember about this week?",
           'Wednesday was just a really good day. Nothing special happened but everything felt easy. I want to remember that those days exist.')
make_entry(demo_user, week2_start, 'how did you show up for a loved one in your life?',
           "Helped my roommate proofread a big email she was nervous about. She said she always forgets I'm good at that. Made me feel useful.")

WeeklyDigest.find_or_create_by!(user: demo_user, week_start_date: week2_start) do |d|
  d.week_number = week2_start.cweek
  d.year = week2_start.year
  d.summary_line = 'Unbothered subway dogs, a rare good day, and a shower idea that actually held up.'
  d.content = "Some weeks have a theme that only reveals itself at the end. This one was about ease.\n\nThere was a dog on the subway who had completely mastered the art of not caring — sitting still, deeply unbothered, as the world moved around him. I thought about that dog more than once this week.\n\nI took an actual lunch break. Sat outside. Didn't look at my phone. It felt almost transgressive to admit, but also a sign it was overdue. The afternoon went better after that.\n\nWednesday was just a good day. Nothing extraordinary — everything felt easy. I want to hold onto the fact that those days happen.\n\nA shower idea survived contact with a notepad, which is rare. My roommate needed help with a stressful email and I was useful. I'm looking forward to seeing my parents next month and realizing, again, that being home feels better than I always expect.\n\nA quiet week. A good one."
  d.status = 'published'
end

# ---------------------------------------------------------------------------
# Week 3 — current week: partial entries + draft digest
# ---------------------------------------------------------------------------
week3_start = Date.current.beginning_of_week(:monday)

make_entry(demo_user, week3_start, "what's something that made you laugh today?",
           "Autocorrect changed 'let me know' to 'let me meow' in a work email and I almost sent it. Almost.")
make_entry(demo_user, week3_start, "what's something nice you did for yourself?",
           "Finally made the appointment I'd been putting off for three months. Just scheduling it felt like a weight lifted.")
make_entry(demo_user, week3_start, 'what made you excited this week?',
           "Found a coffee shop I'd never been to that has exactly the right vibe — not too quiet, not too loud, good light. Adding it to the rotation.")

WeeklyDigest.find_or_create_by!(user: demo_user, week_start_date: week3_start) do |d|
  d.week_number = week3_start.cweek
  d.year = week3_start.year
  d.summary_line = 'Week in progress...'
  d.content = 'This week is still unfolding.'
  d.status = 'draft'
end

# ---------------------------------------------------------------------------
# follower1 published digest — populates the feed for demo_user
# ---------------------------------------------------------------------------
WeeklyDigest.find_or_create_by!(user: follower1, week_start_date: week2_start) do |d|
  d.week_number = week2_start.cweek
  d.year = week2_start.year
  d.summary_line = 'A week of good reads, long walks, and finally finishing that project.'
  d.content = "I finished the project I have been circling for months. Not perfectly, but done — and done turned out to feel a lot better than in-progress.\n\nTook two long walks this week with no destination. The second one ended at a bookshop I'd forgotten existed, where I bought three books I probably won't read immediately but felt good about buying.\n\nSomeone at work said something unexpectedly kind in a meeting and I thought about it for the rest of the day. The bar is low for unexpected kindness but the effect lasts longer than expected kindness, which is interesting.\n\nGood week. Tired, but the good kind."
  d.status = 'published'
end

Rails.logger.debug 'Demo seed complete.'
