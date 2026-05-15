Rails.logger.debug "Seeding calming books articles..."

admin = User.find_by(email: "john.doe@example.com") || User.first
account = admin.account

books = [
  {
    title: "Notes from an Island",
    description: "Tove Jansson's most personal book - a memoir and homage to the island she and her partner loved intensely. Features beautiful illustrations.",
    body: <<~HTML
      <p><strong>Notes from an Island</strong> by Tove Jansson</p>
      <p>In her late forties, Tove Jansson built a cabin on Klovharun, an almost barren outcrop of rock in the Gulf of Finland. For twenty-six summers, Tove and Tuulikki retreated to the island to live, paint and write, inspired and energised by the solitude and shifting seascapes.</p>
      <p>"We built the cabin for our summer holidays, for painting and writing and simply existing, with only the bare necessities. No electricity, no running water. Just the sound of the sea and the wind."</p>
      <p>Features subtle washes and aquatints by Tuulikki Pietilä and Tove's sparse prose, <em>Notes from an Island</em> wonderfully brings together the meditative beauty of the two artists' work.</p>
      <p>The book captures the essence of finding peace in simplicity - building a life with less, but experiencing more. It's about the profound impact that solitude and connection to nature can have on creativity and wellbeing.</p>
      <p>"The island taught me that happiness is not found in accumulation but in attention - in truly seeing the world around us, whether it's the play of light on water or the silhouette of a seabird against the sky."</p>
      <p>This is a book to be savoured slowly, ideally with a view of water nearby. Perfect for anyone seeking permission to slow down and retreat into themselves.</p>
      <hr>
      <p><strong>Why it calms:</strong> Jansson's prose is spare and meditative, like the island life she describes. Her acceptance of solitude and nature provides a template for finding calm in our own overstimulated lives.</p>
    HTML
  },
  {
    title: "The Things You Can See Only When You Slow Down",
    description: "A Buddhist meditation teacher's guide to wellbeing, mindfulness, and joy in love, friendship, work, and spirituality.",
    body: <<~HTML
      <p><strong>The Things You Can See Only When You Slow Down</strong> by Haemin Sunim</p>
      <p>In this stunning and soothing book, Haemin Sunim, a Buddhist meditation teacher born in Korea and educated in the US, shares his advice for wellbeing, mindfulness, and joy in love, friendship, work, and spirituality.</p>
      <p>"The faster we go, the more we miss. The slower we move, the more we see. In stillness lies wisdom, and in wisdom lies peace."</p>
      <p>The book is organized into short chapters, each focusing on a different aspect of life - love, friendship, work, spirituality. Each chapter offers gentle wisdom and practical advice, written in a warm, accessible tone that feels like receiving counsel from a trusted teacher.</p>
      <p>What makes this book particularly special is its visual design. The book contains over thirty full-page colourful and calming illustrations that help you slow down just by looking at them.</p>
      <p><strong>On love:</strong> "When we truly love someone, we don't try to change them. We embrace their entirety, including their flaws and imperfections. Love is not about perfection but about presence."</p>
      <p><strong>On work:</strong> "If you find your work stressful, ask yourself: Am I working to live, or living to work? The answer may reveal whether you've lost your balance."</p>
      <p><strong>On mindfulness:</strong> "Being mindful doesn't mean emptying your mind of thoughts. It means observing your thoughts without judgment. You are not your thoughts. You are the awareness behind them."</p>
      <p>To best enjoy this book, I recommend getting the little hardback edition if you can. The compact size invites you to pick it up often, perhaps reading just a page or two during a break.</p>
      <hr>
      <p><strong>Why it calms:</strong> The short chapters and beautiful illustrations make this an ideal bedside book. Sunim's gentle wisdom provides a framework for understanding that peace is not found in achievement but in presence.</p>
    HTML
  },
  {
    title: "The Bear",
    description: "A gorgeous end-of-the-world book set in an Edenic future of calm streams, towering forests, and wildflower-covered mountainsides.",
    body: <<~HTML
      <p><strong>The Bear</strong> by Andrew Krivak</p>
      <p>This poignant yet peaceful book is about the two last inhabitants on Earth: a girl and her father living in the shadow of a lone mountain.</p>
      <p>The world has ended, but this is not a story of despair. It is a story of Eden - of streams where fish leap, forests where deer graze, mountainsides covered in wildflowers. The prose is lyrical, almost biblical in its rhythms.</p>
      <p>"She had learned that the forest provides, if you know how to listen. The mushrooms in spring, the berries in summer, the nuts in autumn. The deer move slowly through the meadow in the early morning, and they taught her patience."</p>
      <p>To prepare his daughter for adulthood, the father teaches her how to fish, read the secrets of the seasons, and navigate by the stars. He teaches her that there are lessons all around, if only she can learn to listen.</p>
      <p>"The greatest gift I can give you," he tells her, "is the ability to feed yourself, to find water, to read the world. These are the only skills that matter now."</p>
      <p>But when the girl finds herself alone in an unknown landscape, it is a bear that will lead her back home through the vast wilderness.</p>
      <p>"The bear moved slowly, as if it had all the time in the world. She understood then that this was how she must move too. Not with urgency but with attention. Not running toward or away from anything, but simply being present to each moment."</p>
      <p>This is a book about what truly matters when everything else is stripped away. It is about our relationship with nature, with memory, with love.</p>
      <hr>
      <p><strong>Why it calms:</strong> Krivak's prose is extraordinarily beautiful - slow, precise, and attentive. The book's pace itself is a meditation, teaching readers that slowness is not inefficiency but a form of wisdom.</p>
    HTML
  },
  {
    title: "Consolations of the Forest: Alone in a Cabin on the Siberian Taiga",
    description: "The modern counterpart to Thoreau's Walden, about one man's summer spent in a wooden cabin by Siberia's Lake Baikal.",
    body: <<~HTML
      <p><strong>Consolations of the Forest</strong> by Sylvain Tesson</p>
      <p>"As long as there is a cabin deep in the woods, nothing is completely lost."</p>
      <p>This is a peaceful memoir about escaping the chaos of modern life and rediscovering the luxury of solitude. Sylvain Tesson, a French adventurer and writer, spends six months in a wooden cabin by Siberia's Lake Baikal - the world's deepest and oldest freshwater lake.</p>
      <p>"I came to the cabin to escape. Not from anything specific, but from the noise. The notifications, the appointments, the endless performance of being busy. The cabin offered silence, and at first, I didn't know what to do with it."</p>
      <p>Tesson shares the story of his time living a full day's hike from any neighbour, with only his thoughts, his books, a couple of dogs, and many bottles of vodka for company.</p>
      <p>"The forest does not care about your problems. It has its own rhythm, its own concerns. Trees grow, rivers flow, seasons change. To enter the forest is to step outside of time, and in that stepping outside, to find rest."</p>
      <p>The book alternates between Tesson's personal reflections and his encounters with the natural world. He writes about the weather, about the animals, about the stars visible through the cabin's window. He reads - voraciously - and shares his thoughts on literature, philosophy, and the human condition.</p>
      <p>"Walden asked what you can do without. I came to the taiga to discover what I could not live without, and found that the list was shorter than I imagined."</p>
      <p>His greatest discovery is solitude - not loneliness, but the profound peace that comes from being truly alone with oneself and with nature.</p>
      <hr>
      <p><strong>Why it calms:</strong> Tesson's writing has a meditative quality. His descriptions of nature and solitude provide a vicarious escape from the overwhelming noise of modern life.</p>
    HTML
  },
  {
    title: "Mirrors in the Earth: Reflections on Self-Healing from the Living World",
    description: "A nature therapy session for the soul, sharing twelve essays on the benevolence of the living world.",
    body: <<~HTML
      <p><strong>Mirrors in the Earth</strong> by Asia Suler</p>
      <p>In this relaxing book, herbalist and writer Asia Suler braids poetic nature writing with exercises and reflection prompts to help us more deeply nurture and accept ourselves.</p>
      <p>"The earth mirrors us back to ourselves. In the cycles of the seasons, we see our own cycles of growth and rest. In the compost heap's transformation of decay into life, we find hope for our own renewal."</p>
      <p>Each chapter explores a different aspect of the natural world and what it can teach us about healing and self-acceptance.</p>
      <p><strong>On trees:</strong> "Trees teach us that strength is not about rigidity. A tree that bends with the wind survives. One that refuses to bend breaks. Flexibility is not weakness - it is intelligence."</p>
      <p><strong>On seeds:</strong> "A seed must crack open before it can grow. This is the nature of transformation. We too must allow ourselves to be cracked open by life before we can expand into new versions of ourselves."</p>
      <p><strong>On water:</strong> "Water is patient. It does not rush. It does not force. It simply continues moving, century after century, carving canyons not through violence but through persistence."</p>
      <p>Through these metaphors, Suler shares that by connecting more deeply with the living world, we unlock healing connections to ourselves and best remember our innate goodness, empathy, and capacity for compassion.</p>
      <p>"The earth is not a resource to be used. It is a community to which we belong. When we remember this, we stop treating ourselves as resources too - as machines to be optimized, as problems to be fixed."</p>
      <p>The book includes practical exercises - things to notice on walks, questions to reflect upon, invitations to spend time in nature and observe.</p>
      <hr>
      <p><strong>Why it calms:</strong> Suler's writing weaves together the natural world and the inner world of emotion and spirit. Her approach is gentle, encouraging readers to find healing through attention and presence.</p>
    HTML
  },
  {
    title: "Collected Poems",
    description: "A doorway into the majestic world of the great English poet William Wordsworth.",
    body: <<~HTML
      <p><strong>Collected Poems</strong> by William Wordsworth</p>
      <p>Alongside W. B. Yeats and Edward Thomas, Wordsworth will always be one of the go-to poets for anyone seeking calm and perspective.</p>
      <p>"I wandered lonely as a cloud<br>That floats on high o'er vales and hills,<br>When all at once I saw a crowd,<br>A host of golden daffodils..."</p>
      <p>There is magic in Wordsworth's ability to transform ordinary scenes into moments of transcendence. A field of daffodils becomes a celebration of joy. A simple walk becomes a spiritual journey.</p>
      <p>"Because theNDle of nature is so permanent, while other interests are so transitory, we spontaneously turn to nature for refreshment and renovation. The open sky, the mountains, the sea - they remain. We change, but they don't, and in their permanence we find peace."</p>
      <p>I have memorized several of Wordsworth's poems to mull over on train journeys, while hiking in beautiful places, or when I need some time alone. There are far worse ways I could use up my mental space than filling it with his verses.</p>
      <p><em>Lines Composed a Few Miles Above Tintern Abbey</em> is perhaps his masterpiece - a meditation on memory, nature, and how both can heal and sustain us across the years:</p>
      <p>"...and the deep power of joy,<br>When the eye of the mind hath a pause upon peace,<br>And feels the happiness of a present without a past."</p>
      <p>Wordsworth reminds us that we can return to nature again and again for the same refreshment, that the natural world is not depleted by our attention but enriched by it.</p>
      <hr>
      <p><strong>Why it calms:</strong> Poetry offers us language for experiences we struggle to articulate. Wordsworth captures the peace of solitary walks in nature so perfectly that simply reading his words can induce that same peace.</p>
    HTML
  },
  {
    title: "Nothing Much Happens: Calming Stories to Soothe Your Mind & Help You Sleep",
    description: "Peace-engineered stories in which unnamed narrators recount their days and evoke the distinct comforts of each season.",
    body: <<~HTML
      <p><strong>Nothing Much Happens</strong> by Kathryn Britton</p>
      <p>If you struggle with insomnia or anxiety, you might have heard of the Nothing Much Happens podcast. This is the companion book, offering peace-engineered stories in which unnamed, gender-neutral narrators recount their days and evoke the distinct comforts offered by each of the four seasons.</p>
      <p>The book's premise is simple but powerful: sometimes our minds need a gentle story to follow, something without drama or tension, something that simply describes the quiet pleasure of everyday activities.</p>
      <p><strong>Winter:</strong> "The morning begins with light through the window. The coffee maker does its quiet work. The snow has come overnight, covering everything in white. The narrator puts on boots and a coat and steps outside. Each breath is visible in the cold air. The world is still. A cardinal lands on the fence post."</p>
      <p><strong>Spring:</strong> "The garden is waking up. The tulips are pushing through the soil. The days are longer now. The narrator opens the windows to let in the air. A robin hops on the lawn, head tilting. Seeds are ordered from the catalogue. Anticipation begins."</p>
      <p><strong>Summer:</strong> "The tomatoes are ripening on the windowsill. The lemonade is cold. The sprinkler makes its arc in the afternoon heat. The narrator sits in the shade with a book. The pages are warm from the sun. A butterfly moves through the garden."</p>
      <p><strong>Autumn:</strong> "The apples are ready. The leaves are turning gold. The smell of cinnamon drifts from the kitchen. The jumper is pulled from the closet. The narrator walks through leaves that crunch softly. The light is slanted and golden."</p>
      <p>There is no plot, no conflict, no resolution needed. There is just the present moment, described with care and attention.</p>
      <hr>
      <p><strong>Why it calms:</strong> The stories are designed to give your mind something soothing to follow, like a fireside chat with a calm friend. They're perfect for reading before sleep.</p>
    HTML
  },
  {
    title: "Kafka on the Shore",
    description: "Murakami at his best: weird yet soothing, escapist yet perceptive about what it feels like to be human.",
    body: <<~HTML
      <p><strong>Kafka on the Shore</strong> by Haruki Murakami</p>
      <p>In a Reddit thread about the most relaxing books, one reader shared: "there was a period of life when I had really bad anxiety. And for some reason, reading Murakami was very calming." This reviewer could not agree more.</p>
      <p>Murakami at his best: weird yet soothing, escapist yet still so perceptive about what it feels like to be human.</p>
      <p>Comprising two distinct but interrelated plots, the narrative runs back and forth between the life of fifteen-year-old Kafka Tamura, who has run away from home, and an aging man called Nakata, who can speak with cats.</p>
      <p><em>Part One:</em></p>
      <p>"My fifteen-year-old self, in the summer of 1970, had no idea what was coming. I left home because I had to, because the alternative was staying in a house that had become unbearable. Sometimes you have to leave before you can understand why you needed to go.</p>
      <p>I took a train south. The ticket collector gave me a sleeping car reserved seat. I watched the landscape change through the window - industrial areas giving way to suburbs, suburbs to countryside, countryside to mountains. Each change felt like shedding a skin."</p>
      <p>"People's memories are strange things. Some we keep forever, others vanish like steam. I remember the color of the curtains in my childhood bedroom. I remember the smell of the library. But last week's conversations? Gone.</p>
      <p>This is not a tragedy. It is a mercy. If we remembered everything, we could never move forward."</p>
      <p><em>Part Two:</em></p>
      <p>Nakata has never quite fit in. After an accident in childhood that left him different - simple, quiet, unable to read people's faces but able to hear what cats say - he has drifted through life. When he is fired from his factory job, he sets out on a journey that will change everything.</p>
      <p>"I never understood why people made things so complicated. Life is simple. You eat when you are hungry, sleep when you are tired, and that is enough. The complications come when we try to be more than we are."</p>
      <p>"Sometimes fate is like a small sandstorm that follows you. The storm is not what you are running from - you are running to find shelter from the storm. And when you find that shelter, you realize you were running toward it all along."</p>
      <p>This is one of the best books to get lost in - not because it requires intense focus, but because the world Murakami creates is so vivid and immersive that you want to stay there.</p>
      <hr>
      <p><strong>Why it calms:</strong> Murakami's prose is hypnotic and rhythmic, almost meditative. The dreamlike quality of his narratives creates a space where anxiety about ordinary life can temporarily dissolve.</p>
    HTML
  },
  {
    title: "A Thousand Mornings",
    description: "One of the most soothing books with perceptive and gently wise writing about the natural world.",
    body: <<~HTML
      <p><strong>A Thousand Mornings</strong> by Mary Oliver</p>
      <p>One of the most soothing books and some of the most perceptive and gently wise writing, about the natural world and our place within it.</p>
      <p>"Every morning the shore a different indifference. The sea, though, does not know their time. It keeps its own time."</p>
      <p>Mary Oliver writes about what she sees on her daily walks - the birds, the flowers, the weather, the changing seasons. But she also writes about attention itself, about how paying close attention to the world is a form of prayer.</p>
      <p>"I do not want to end up simply having visited this world."</p>
      <p>This collection includes poems that seem to capture universal truths in simple observations of nature. A spider building its web. A heron standing in still water. The way light falls through leaves.</p>
      <p><em>Spring</em></p>
      <p>"Somewhere downstream, the ice broke apart. I could hear it last night - a distant, explosive sound, like the world cracking open. Now the river runs free again, brown and fast and jubilant.</p>
      <p>What does this teach us? That which seems frozen can suddenly give way. That which seems dead can spring back to life. That there is always another current, always another chance."</p>
      <p><em>Summer</em></p>
      <p>"The fireflies appear at dusk, their light punctuation against the darkening air. I catch one, hold it gently in my palm. It glows for a moment, then goes dark. I open my hand. It flies, glowing again as it rises, as if it is making its own small declaration of joy.</p>
      <p>Who am I to say it is not?"</p>
      <p><em>Autumn</em></p>
      <p>"The geese do not ask permission to fly south. They simply go, following some imperative older than thought. Sometimes I watch them and feel the pull of that same certainty - the desire to move toward warmth, toward light, toward whatever is calling me.</p>
      <p>Maybe my call is quieter. Maybe I have to listen more carefully. But it is there, and the geese remind me to follow it."</p>
      <p>For some truly relaxing reading, grab a copy and head outside, find a lovely spot to sit, and take in Oliver's peaceful words surrounded by fresh air and with the sun on your face.</p>
      <hr>
      <p><strong>Why it calms:</strong> Oliver's poems are like permission slips - they remind us that spending time watching birds and noticing flowers is not a waste of time but an essential form of self-care.</p>
    HTML
  },
  {
    title: "The Long Way to a Small, Angry Planet",
    description: "An easygoing, wholesome book from the queen of hopeful sci-fi.",
    body: <<~HTML
      <p><strong>The Long Way to a Small, Angry Planet</strong> by Becky Chambers</p>
      <p>Becky Chambers is writing some of the most heartwarming and wholesome books today, both in her new Monk and Robot series and in this earlier Wayfarers series.</p>
      <p>Commenting on the first book, one reader writes: "I cannot recommend this enough. It leaves you feeling incredibly warm and wholesome and like everything will be ok."</p>
      <p>The story follows a crew aboard the spacecraft <em>Wayfarer</em> as they journey through deep space to complete a job - tunneling through a wormhole to an alien network. But the job is almost beside the point.</p>
      <p>What matters is the crew. There is Rosemary Harper, the new hire who is running from something. There is Benjach, the ship's captain who is trying to keep everyone alive. There is Keryl, a pilot who loves mushrooms. There is Sissix, a reptilian alien who is learning about love. And there is Jenks, a Datasee who is figuring out what it means to be alive.</p>
      <p>"The Wayfarer is not a beautiful ship. It is cramped and old and held together with patches and hope. But it is home, and its crew are family."</p>
      <p>The book explores themes of found family, of acceptance, of what it means to live alongside people who are different from you. It is optimistic without being naive.</p>
      <p>"Not all storms come with clouds. Some come as loneliness, or uncertainty, or the quiet knowledge that you do not quite fit anywhere. The trick is learning to build a shelter that can hold you until the sky clears."</p>
      <p><em>The Wayfarer</em> crew lives in a future where humanity has learned to coexist with alien species, where differences are sources of enrichment rather than conflict.</p>
      <p>"We are all passengers on this journey together. Some of us are traveling the same direction, some different. But we share the same ship, and that makes us family."</p>
      <p>A perfect escape when you need something calming and uplifting.</p>
      <hr>
      <p><strong>Why it calms:</strong> Chambers creates a world where kindness is the default setting, where people and aliens look out for each other. Reading her books is like a warm bath for the soul.</p>
    HTML
  },
  {
    title: "A Calendar of Wisdom: Daily Thoughts to Nourish the Soul",
    description: "Leo Tolstoy's spiritual guide with one page of wisdom per day.",
    body: <<~HTML
      <p><strong>A Calendar of Wisdom</strong> by Leo Tolstoy</p>
      <p>What Tolstoy considered his most important contribution to humanity - a compilation of daily thoughts to nourish the soul with one page of wisdom per day.</p>
      <p>Tolstoy spent years compiling quotations from the world's wisdom traditions - the New Testament, Greek philosophy, Buddhist sutras, Confucian teachings, and the essays of both ancient writers and contemporary thinkers. He organized them by the day, creating a year-long companion for spiritual reflection.</p>
      <p><strong>January 1</strong></p>
      <p>"The strongest of all warriors are these two - Time and Patience."</p>
      <p><strong>January 15</strong></p>
      <p>"If you want to be happy, let your life be a stream that flows quietly between two banks - the bank of duty and the bank of joy. Both are necessary. Neither alone is enough."</p>
      <p><strong>March 8</strong></p>
      <p>"The purpose of life is not to be happy. The purpose of life is to be useful, to be responsible, to be compassionate. It is, in short, to matter - to count, to stand for something, to have made a difference that will outlast our brief time here."</p>
      <p><strong>June 21</strong></p>
      <p>"Everyone thinks of changing the world, but no one thinks of changing himself. Begin there. The world will be different because you are different."</p>
      <p><strong>September 3</strong></p>
      <p>"Act with certainty, speak with hesitation. The fool speaks without thinking. The wise thinks before speaking. But the truly wise speaks only when the moment requires it."</p>
      <p>I love to keep my copy on my desk rather than hidden on a shelf - it is perfect to pick up for some wise and calming reading when I need it most.</p>
      <p>"As you grow older, you will discover that the most important things in life are not things at all. They are moments - moments of connection, of kindness, of understanding. They are the times when we truly see each other."</p>
      <hr>
      <p><strong>Why it calms:</strong> Tolstoy draws from thousands of years of human wisdom. Opening to any page provides immediate perspective, and the daily format encourages regular, contemplative reading.</p>
    HTML
  },
  {
    title: "Goodbye, Things",
    description: "A remarkably peaceful book and a fantastic guide to decluttering your life.",
    body: <<~HTML
      <p><strong>Goodbye, Things</strong> by Fumio Sasaki</p>
      <p>Fumio Sasaki does not claim to be a minimalism expert or a decluttering guru. He is just a regular guy who wanted to say goodbye to everything he did not absolutely need. This book is the story of his journey and the results.</p>
      <p>"I used to own a lot of things. Books I had not read. Clothes I had not worn. Electronic gadgets I had not used more than once. I thought having things meant something. That it reflected who I was."</p>
      <p>"Then I traveled. And when I traveled, I realized I could fit everything I needed into one bag. A few clothes, a notebook, a pen. That was it. And I was fine. More than fine - I was free."</p>
      <p>Not only is the book peaceful to read, but it will help you make room for what is most important.</p>
      <p><strong>On the psychology of stuff:</strong></p>
      <p>"We do not just own our things. Our things own us. We spend time maintaining them, organizing them, worrying about them. We check our email about new purchases. We drive to stores. We compare what we have with what others have. All of this costs time and energy."</p>
      <p>"The average person in our society owns perhaps three thousand to five thousand items. Imagine the freedom if you reduced that number by half. Or by three-quarters."</p>
      <p><strong>On what remains:</strong></p>
      <p>"When you eliminate the unnecessary, you discover what is truly necessary. Not things, but experiences. Not status, but connection. Not efficiency, but presence."</p>
      <p>"My apartment now has almost nothing in it. A mattress on the floor. A small table. A bookshelf with perhaps thirty books - the ones I truly love. And that is enough."</p>
      <p><strong>On letting go:</strong></p>
      <p>"Letting go is not a single event. It is a practice. Each day, we choose again what to keep and what to release. The goal is not perfection but progress."</p>
      <p>"Goodbye, things. Hello, life."</p>
      <hr>
      <p><strong>Why it calms:</strong> Sasaki's writing is direct and practical. But beyond the practical advice, there is a deeper message: that freedom comes not from having more but from needing less.</p>
    HTML
  },
  {
    title: "The Haiku of Basho",
    description: "The special magic that comes from reading a haiku to help calm your mind.",
    body: <<~HTML
      <p><strong>The Haiku of Basho</strong> by Matsuo Basho</p>
      <p>Basho's poetry offers the special magic that comes from reading a haiku to help calm your mind and feel less stressed.</p>
      <p>The haiku is a Japanese poetic form consisting of seventeen syllables, typically capturing a single moment of awareness or a brief sensory experience. Basho (1644-1694) is considered the master of the form.</p>
      <p><strong>The most famous:</strong></p>
      <p>"Sitting quietly,<br>doing nothing,<br>Spring comes,<br>and the grass grows,<br>by itself."</p>
      <p>This poem is itself a meditation on stillness. To sit quietly and do nothing is not inactivity but active attention. And in that attention, the world continues - spring comes, the grass grows - without any intervention from us.</p>
      <p><strong>Another favorite:</strong></p>
      <p>"An old silent pond<br>A frog jumps into the pond<br>Splash! Silence again."</p>
      <p>The power of this poem is in its juxtaposition - the sudden movement and sound breaking the deep stillness, then the stillness returning. It captures how disruption and peace alternate in our lives.</p>
      <p><strong>On a journey:</strong></p>
      <p>"The light of the candle<br>Is flickering<br>Both of us<br>Are strangers<br>In this world."</p>
      <p><strong>On nature:</strong></p>
      <p>"Over the wintry<br>Forest, the wind makes its way<br>Inaccessible<br>Snow."</p>
      <p>I keep a collection of Basho's poetry near me when I am working and often read a calming haiku or two when I need a break.</p>
      <p>"A haiku does not try to capture everything. It finds the single detail that contains the whole. The single drop of water that holds the reflection of the moon. The single moment that holds the whole truth."</p>
      <p>Each haiku is complete in itself - a small poem containing a world.</p>
      <hr>
      <p><strong>Why it calms:</strong> Haiku are short enough to read in a breath but rich enough to sit with for hours. Basho's images are simple but profound, offering moments of clarity and calm.</p>
    HTML
  },
  {
    title: "Wind, Sand and Stars",
    description: "Antoine de Saint-Exupery's best-loved book after The Little Prince.",
    body: <<~HTML
      <p><strong>Wind, Sand and Stars</strong> by Antoine de Saint-Exupery</p>
      <p>One of Antoine de Saint-Exupery's best-loved books (after The Little Prince, that is). Saint-Exupery was a pioneering aviator, and this book is a meditation on flight, on adventure, and on what it means to truly live.</p>
      <p>The prose is beautifully calming, with descriptions of the natural world that transport you:</p>
      <p>"When I opened my eyes I saw nothing but the pool of nocturnal sky, for I was lying on my back with out-stretched arms, face to face with that hatchery of stars. Only half awake, still unaware that those depths were sky, having no roof between those depths and me..."</p>
      <p><strong>On the desert:</strong></p>
      <p>"The desert is not hostile. It is indifferent. It does not judge you. It does not want anything from you. It simply exists, vast and silent and full of stars. In that existence, there is a strange comfort."</p>
      <p><strong>On flight:</strong></p>
      <p>"In flight, you learn that the machine is nothing. The pilot is nothing. What matters is the relationship between the two - the skill that comes from attention, from presence, from hours spent in the sky learning to feel the air."</p>
      <p><strong>On connection:</strong></p>
      <p>"We are not alone in the universe. We are connected by invisible threads - the threads of radio that bind one pilot to another across the night sky. When my lights flicker, another plane answers. When I am lost, a voice comes through the static: I am here. You are not alone."</p>
      <p>Saint-Exupery writes about crashes in the desert, about the isolation and terror of being lost, but also about the profound beauty of the night sky and the camaraderie of those who fly.</p>
      <p>"There is a kind of peace in the air that is different from any peace on the ground. Perhaps it is the peace of the alone-ness that we all seek - the solitude that is not loneliness but fullness."</p>
      <p>Perfect to take with you when traveling, or as the source of another adventure while sitting at home.</p>
      <hr>
      <p><strong>Why it calms:</strong> Saint-Exupery's writing has a grandeur that puts our small worries into perspective. His descriptions of the natural world - the desert, the stars, the wind - are awe-inspiring and strangely comforting.</p>
    HTML
  }
]

books.each do |book|
  Article.find_or_create_by(title: book[:title]) do |a|
    a.account = account
    a.description = book[:description]
    a.body = book[:body]
    a.status = "published"
  end
end

Rails.logger.debug { "Seeded #{books.size} calming books articles" }
